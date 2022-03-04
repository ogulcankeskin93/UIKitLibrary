//
//  WebViewWrapper.swift
//  UIKitLibrary
//
//  Created by Ogulcan Keskin on 3.03.2022.
//

import SwiftUI

struct WebViewWrapper: View {
    var body: some View {
        UIViewControllerPreview {
            WebViewController()
        }
        .ignoresSafeArea()
    }
}

struct WebViewWrapper_Previews: PreviewProvider {
    static var previews: some View {
        WebViewWrapper()
    }
}


import UIKit
import WebKit

class WebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            webView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
        ])
        
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "toggleMessageHandler")
        
        contentController.add(self, name: "setToken")

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        
        let js = """
            var _selector = document.querySelector('input[name=myCheckbox]');
            _selector.addEventListener('change', function(event) {
                var message = (_selector.checked) ? "Toggle Switch is on" : "Toggle Switch is off";
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.toggleMessageHandler) {
                    window.webkit.messageHandlers.toggleMessageHandler.postMessage({
                        "message": message
                    });
                }
            });
        """
        
        let passtoken = """
                window.webkit.messageHandlers.setToken.postMessage(TOKEN_STRING);
        """

        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)
    }

    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
}

extension WebViewController: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }
        print(dict)
        if message.name == "toggleMessageHandler" {
            toggleOption(dict: dict)
            
        } else {
            
        }
      
    }
    
    func toggleOption(dict: [String: AnyObject]) {
        guard let message = dict["message"] else {
            return
        }
        let script = "document.getElementById('value').innerText = \"\(message)\""

        webView.evaluateJavaScript(script) { (result, error) in
            if let result = result {
                print("Label is updated with message: \(result)")
            } else if let error = error {
                print("An error occurred: \(error)")
            }
        }
    }
}
