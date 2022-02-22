//
//  MaskExampleWrapper.swift
//  UIKitLibrary
//
//  Created by Ogulcan Keskin on 11.02.2022.
//

import UIKit
import SwiftUI

struct MaskExampleWrapper: View {
    var body: some View {
        UIViewControllerPreview {
            MaskExampleViewController()
        }
        .ignoresSafeArea()
    }
}

class MaskExampleViewController: UIViewController {
    
    lazy var greenBlock: GoldenView = {
        let block = GoldenView(frame: self.view.frame)
        block.backgroundColor = .green.withAlphaComponent(0.8)
        block.translatesAutoresizingMaskIntoConstraints = false
        return block
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        self.view.addSubview(greenBlock)
        
        self.mask()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.greenBlock.addGestureRecognizer(tap)
    }
    
    @objc
    func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        self.greenBlock.backgroundColor = Int.random(in: 1...10) % 2 == 0 ? .red : .blue
    }
    
    func mask() {
        let bezier = UIBezierPath(ovalIn: .init(x: 50, y: 400, width: 150, height: 150))
        let layer = CAShapeLayer()
        layer.path = bezier.cgPath
        layer.lineDashPattern = [8, 7.2]
        layer.lineWidth = 1.5
        layer.lineCap = .round
        layer.fillColor = UIColor.red.cgColor
        layer.strokeColor = UIColor.blue.cgColor
        layer.position = .zero
        self.greenBlock.layer.mask = layer
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
        greenBlock.addGestureRecognizer(recognizer)
    }
    @objc
    func handlePan(recognizer: UIPanGestureRecognizer) {
        var translation = recognizer.translation(in: self.view)
        translation = CGPoint(x: translation.x, y: translation.y)
        greenBlock.center = CGPoint(x: greenBlock.center.x + translation.x, y: greenBlock.center.y + translation.y)
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
}

class GoldenView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let bezier = UIBezierPath(ovalIn: .init(x: 50, y: 400, width: 150, height: 150))
        let layer = CAShapeLayer()
        layer.path = bezier.cgPath
        layer.lineDashPattern = [8, 7.2]
        layer.lineWidth = 1.5
        layer.lineCap = .round
        layer.fillColor = UIColor.red.cgColor
        layer.strokeColor = UIColor.blue.cgColor
        layer.position = .zero
        
        return layer.path?.contains(point) ?? true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct MaskExampleWrapper_Previews: PreviewProvider {
    static var previews: some View {
        MaskExampleWrapper()
    }
}
