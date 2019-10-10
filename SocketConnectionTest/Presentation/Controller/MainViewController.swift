//
//  ViewController.swift
//  SocketConnectionTest
//
//  Created by Anastasia Markovets on 07/10/2019.
//  Copyright © 2019 Anastasia Markovets. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    var socketConnector:SocketDataManager!
    @IBOutlet weak var ipAddressField: UITextField!
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var messageField: UITextField!
    @IBOutlet weak var messageHistoryView: UITextView!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var disconnectBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socketConnector = SocketDataManager(with: self)
        resetUIWithConnection(status: false)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }


    @IBAction func connect(){
        guard let ipAddr = ipAddressField.text, let portVal = portField.text  else {
            return
        }
        
        let soc = DataSocket(ip: ipAddr, port: portVal)
        socketConnector.connectWith(socket: soc)
    }
    
    @IBAction func disconnect(_ sender: Any) {
        socketConnector.disconnect()
    }
    
    @IBAction func send(){
        guard let msg = messageField.text else {
            return
        }
        
        send(message: msg)
        messageField.text = ""
    }
    
    func send(message: String){
        socketConnector.send(message: message)
        update(message: "me:\(message)")
    }
    
}

extension MainViewController: PresenterProtocol{
    
    func resetUIWithConnection(status: Bool){
        ipAddressField.isEnabled = !status
        portField.isEnabled = !status
        messageField.isEnabled = status
        connectBtn.isEnabled = !status
        sendBtn.isEnabled = status
        disconnectBtn.isEnabled = status
        
        if (status){
            updateStatusViewWith(status: "Connected")
            statusView.backgroundColor = UIColor(red: 191/255, green: 233/255, blue: 175/255, alpha: 1)
        } else {
            updateStatusViewWith(status: "Disconnected")
            statusView.backgroundColor = UIColor(red: 244/255, green: 168/255, blue: 139/255, alpha: 1)
        }
    }
    
    func updateStatusViewWith(status: String){
        statusLabl.text = status
    }
    
    func update(message: String){
        if let text = messageHistoryView.text{
            let newText = """
            \(text)            
            \(message)
            """
            messageHistoryView.text = newText
        } else {
            let newText = """
            \(message)
            """
            messageHistoryView.text = newText
        }

        let myRange=NSMakeRange(messageHistoryView.text.count-1, 0);
        messageHistoryView.scrollRangeToVisible(myRange)
        
    }

    
}

