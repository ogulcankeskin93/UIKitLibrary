//
//  ContentView.swift
//  UIKitLibrary
//
//  Created by Ogulcan Keskin on 7.02.2022.
//

import SwiftUI

struct EditableImageViewWrapper: View {
    var body: some View {
        UIViewControllerPreview {
            DragExampleViewController()
        }
        .ignoresSafeArea()
    }
}

class DragExampleViewController: UIViewController {

    static let key = "papadog"
    
    @FileManagerWrapper(key: key, defaultValue: [
        .init(imageName: "adler", frame: .init(x: 200, y: 400, width: 200, height: 200), rotationAngle: 1),
        .init(imageName: "morty-1", frame: .init(x: 300, y: 150, width: 250, height: 250), rotationAngle: 0.5),
        .init(imageName: "morty-2", frame: .init(x: 30, y: 150, width: 300, height: 300), rotationAngle: 0)
    ])
    var imageArray: [ImageProperties]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let greenView = UIView(frame: CGRect(x: 150, y: 160, width: 150, height: 200))
        greenView.backgroundColor = .systemGreen
        view.addSubview(greenView)
        setupImages()
    }
    
    func setupImages() {
        imageArray.map(EditableImageView.init(imageProperties:)).forEach {
            $0.delegate = self
            self.view.addSubview($0)
        }
    }
}

extension DragExampleViewController: EditableImageDelegate {
    func imageEditDidFinish(new imageProperties: ImageProperties) {
        guard let index = imageArray.firstIndex (where: { prop in
            prop.imageName == imageProperties.imageName
        }) else { return }
        imageArray[index] = imageProperties
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EditableImageViewWrapper()
    }
}

protocol EditableImageDelegate: AnyObject {
    func imageEditDidFinish(new imageProperties: ImageProperties)
}


struct ImageProperties: Codable {
    let imageName: String
    let frame: CGRect
    var rotationAngle: CGFloat
    var scale: CGPoint = .init(x: 1, y: 1)
    var center: CGPoint?
}

class EditableImageView: UIView {
    
    weak var delegate: EditableImageDelegate?
    var isEditActive = false
    
    private let imageProperties: ImageProperties
    private var imageView: UIImageView
    
    private var dashedBorder: CAShapeLayer?
    private lazy var dragPanGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dragView))
        return pan
    }()
    
    private var rotateButton: UIImageView = {
        let rotateButton = UIImageView(image: UIImage(systemName: "arrow.up.backward.and.arrow.down.forward")?.withRenderingMode(.alwaysTemplate))
        rotateButton.isUserInteractionEnabled = true
        rotateButton.backgroundColor = .red.withAlphaComponent(0.3)
        rotateButton.translatesAutoresizingMaskIntoConstraints = false
        rotateButton.tintColor = .blue
        return rotateButton
    }()
    
    
    init(imageProperties: ImageProperties) {
        func getImageView(from imageProperties: ImageProperties) -> UIImageView {
            let imageView = UIImageView(image: UIImage(named: imageProperties.imageName))
            imageView.isUserInteractionEnabled = true
            return imageView
        }
        self.imageProperties = imageProperties
        self.imageView = getImageView(from: imageProperties)
        let new = imageProperties.frame.insetBy(dx: -15, dy: -15)
        print(imageProperties.imageName, new)
        super.init(frame: new)
        if let center = imageProperties.center {
            self.center = center
        }
        setupImage()
        setupPosition()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.imageView.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addRotateButton() {
        self.addSubview(rotateButton)
        NSLayoutConstraint.activate([
            rotateButton.heightAnchor.constraint(equalToConstant: 30),
            rotateButton.widthAnchor.constraint(equalToConstant: 30),
            rotateButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 15),
            rotateButton.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -15)
        ])
    }
    
    private func setupImage() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15)
        ])
        
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rotateViewPanGesture(recognizer:)))
        rotateButton.addGestureRecognizer(panRecognizer)
    }
    
    
    private func setupPosition() {
        let scale = CGAffineTransform(scaleX: imageProperties.scale.x, y: imageProperties.scale.y)
        self.transform = scale.rotated(by: imageProperties.rotationAngle)
    }
    
    private func informDelegate() {
        var newImageProperty = self.imageProperties
        newImageProperty.rotationAngle = finalRotationAngle ?? newImageProperty.rotationAngle
        newImageProperty.scale = finalScale ?? newImageProperty.scale
        if let center = lastDraggedCenter {
            newImageProperty.center = center
        }
        delegate?.imageEditDidFinish(new: newImageProperty)
    }
    
    // MARK: Tap
    @objc
    func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        isEditActive.toggle()
        if isEditActive {
            self.addRotateButton()
            self.dashedBorder = imageView.addDashedBorder()
            self.addGestureRecognizer(self.dragPanGesture)
            self.backgroundColor = .red.withAlphaComponent(0.3)
        } else {
            self.rotateButton.removeFromSuperview()
            self.dashedBorder?.removeFromSuperlayer()
            self.removeGestureRecognizer(dragPanGesture)
            informDelegate()
        }
    }
    
    // MARK: ROTATE
    private var deltaAngle: CGFloat!
    private var finalRotationAngle: CGFloat?
    private var finalScale: CGPoint?

    @objc
    func rotateViewPanGesture(recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: self.superview)
        let center = self.center
        
        switch recognizer.state {
        case .began:
            self.deltaAngle = atan2(touchLocation.y - center.y, touchLocation.x - center.x) - rotation(from: transform)
        case .changed:
            let ang = atan2(touchLocation.y - center.y, touchLocation.x - center.x)
            let angleDiff = deltaAngle - ang
         
            // TODO: Scale
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            self.transform = scale.rotated(by: -angleDiff)
            self.finalRotationAngle = -angleDiff

            recognizer.setTranslation(.zero, in: self.superview)
            layoutIfNeeded()
        default:
            break
        }
    }
    
    private func rotation(from transform: CGAffineTransform) -> Double {
        return atan2(Double(transform.b), Double(transform.a))
    }
    
    // MARK: DRAG
    var lastDraggedCenter: CGPoint?
    
    @objc
    func dragView(gesture: UIPanGestureRecognizer) {
        let target = gesture.view!
        let translation = gesture.translation(in: self.superview)
        let newCenter = CGPoint(x: target.center.x + translation.x, y: target.center.y + translation.y)
        // prevent view hidden around edges
        guard self.superview?.bounds.contains(newCenter) == true else { return }
        target.center = newCenter
        lastDraggedCenter = newCenter
        gesture.setTranslation(.zero, in: self.superview)
    }
}


extension UIView {
    
    @discardableResult
    func addDashedBorder() -> CAShapeLayer {
        let color = UIColor.blue.cgColor
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [6,3]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
        
        self.layer.addSublayer(shapeLayer)
        return shapeLayer
    }
}
