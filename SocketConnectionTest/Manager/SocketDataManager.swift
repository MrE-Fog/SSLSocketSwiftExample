//
//  SocketDataManager.swift
//  SocketConnectionTest
//
//  Created by Anastasia Markovets on 07/10/2019.
//  Copyright © 2019 Anastasia Markovets. All rights reserved.
//

import Foundation

class SocketDataManager: NSObject, StreamDelegate {
    
    var readStream: Unmanaged<CFReadStream>?
    var writeStream: Unmanaged<CFWriteStream>?
    var inputStream: InputStream?
    var outputStream: OutputStream?
    var messages = [AnyHashable]()
    weak var uiPresenter :PresenterProtocol!
    
    init(with presenter:PresenterProtocol){
        
        self.uiPresenter = presenter
    }
    func connectWith(socket: DataSocket) {

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (socket.ipAddress! as CFString), UInt32(socket.port), &readStream, &writeStream)
        messages = [AnyHashable]()
        open()
    }
    
    func disconnect() {
        
        close()
    }
    
    func open() {
        print("Opening streams.")
        outputStream = writeStream?.takeRetainedValue()
        inputStream = readStream?.takeRetainedValue()
        outputStream?.delegate = self
        inputStream?.delegate = self
        outputStream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
        inputStream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)

        inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)

        inputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
        outputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)

        let sslSettings = [
            NSString(format: kCFStreamSSLValidatesCertificateChain): kCFBooleanFalse,
            NSString(format: kCFStreamSSLIsServer): kCFBooleanFalse,
            NSString(format: kCFStreamSSLCertificates): getKeyChain()
        ] as [NSString : Any]

        inputStream?.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
        outputStream?.setProperty(sslSettings, forKey: kCFStreamPropertySSLSettings as Stream.PropertyKey)
        
        outputStream?.open()
        inputStream?.open()
    }
    
    func close() {
        print("Closing streams.")
        uiPresenter?.resetUIWithConnection(status: false)
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        outputStream?.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream = nil
        outputStream = nil
    }
    
    func getKeyChain() -> CFArray {

        let mainBundle = Bundle.main
        let thePath = mainBundle.path(forResource: Certificate.name, ofType: Certificate.type)!

        let PKCS12Data: NSData = NSData(contentsOfFile: thePath)!

        var items: CFArray?
        let optionDict: NSMutableDictionary = [kSecImportExportPassphrase as NSString: "123"]
        let sanityCheck = SecPKCS12Import(PKCS12Data, optionDict, &items)

        if sanityCheck == errSecSuccess && CFArrayGetCount(items) > 0 {
            return parseKeyChainItems(items!)
        } else {
            switch sanityCheck {
            case errSecSuccess:
                print("Error importing p12: errSecSuccess")
            case errSecUnimplemented:
                print("Error importing p12: errSecUnimplemented")
            case errSecIO:
                print("Error importing p12: errSecIO")
            case errSecOpWr:
                print("Error importing p12: errSecOpWr")
            case errSecParam:
                print("Error importing p12: errSecParam")
            case errSecAllocate:
                print("Error importing p12: errSecAllocate")
            case errSecUserCanceled:
                print("Error importing p12: errSecUserCanceled")
            case errSecBadReq:
                print("Error importing p12: errSecBadReq")
            case errSecInternalComponent:
                print("Error importing p12: errSecInternalComponent")
            case errSecNotAvailable:
                print("Error importing p12: errSecNotAvailable")
            case errSecDuplicateItem:
                print("Error importing p12: errSecDuplicateItem")
            case errSecItemNotFound:
                print("Error importing p12: errSecItemNotFound")
            case errSecInteractionNotAllowed:
                print("Error importing p12: errSecInteractionNotAllowed")
            case errSecDecode:
                print("Error importing p12: errSecDecode")
            case errSecAuthFailed:
                print("Error importing p12: errSecAuthFailed")
            default:
                print("Error importing p12: Unknown items: \(String(describing: items))")
                break
            }
        }
        return [] as CFArray
    }

    func parseKeyChainItems(_ keychainArray: NSArray) -> CFArray {
        print("Key chain array: \(keychainArray)")
        let dict = keychainArray[0] as! Dictionary<String,AnyObject>
        let key = String(kSecImportItemIdentity)
        let identity = dict[key] as! SecIdentity?
        let certArray:[AnyObject] = dict["chain"] as! [SecCertificate]
        var certChain:[AnyObject] = [identity!]
        for item in certArray {
            certChain.append(item)
        }
        
        return certChain as CFArray
    }

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        let streamName = getStreamName(aStream)

        switch eventCode {
        case Stream.Event.openCompleted:
            uiPresenter?.resetUIWithConnection(status: true)
            print("\(streamName).OpenCompleted")
            break
        case Stream.Event.hasBytesAvailable:
            if aStream == inputStream {
                var dataBuffer = Array<UInt8>(repeating: 0, count: 1024)
                var len: Int
                while (inputStream?.hasBytesAvailable)! {
                    len = (inputStream?.read(&dataBuffer, maxLength: 1024))!
                    if len > 0 {
                        let output = String(bytes: dataBuffer, encoding: .ascii)
                        if nil != output {
                            print("server said: \(output ?? "")")
                            messageReceived(message: output!)
                        }
                    }
                }
            }
            print("\(streamName).HasBytesAvailable")
        case Stream.Event.hasSpaceAvailable:
            print("\(streamName).HasSpaceAvailable")
            break
        case Stream.Event.endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            print("\(streamName).EndEncountered")
            uiPresenter?.resetUIWithConnection(status: false)
            break
        case Stream.Event.errorOccurred:
            print("\(aStream.streamError?.localizedDescription ?? "")")
            print("\(streamName).ErrorOccurred")
            break
        default:
            print("\(streamName) unknown event")
            break
        }
    }

    func getStreamName(_ aStream: Stream) -> String {

        if comparedStreamEqual(aStream, bStream: inputStream) {
            return "InputStream"
        } else if comparedStreamEqual(aStream, bStream: outputStream) {
            return "OutputStream"
        }
        
        return "UnknownStream"
    }

    func comparedStreamEqual(_ aStream: Stream? , bStream: Stream?) -> Bool {
        if aStream != nil && bStream != nil {
            if aStream == bStream {
                return true
            }
        }
        return false
    }
    
    func messageReceived(message: String){
        
        uiPresenter?.update(message: "server said: \(message)")
        print(message)
    }
    
    func send(message: String){
        
        let response = "msg:\(message)"
        let buff = [UInt8](message.utf8)
        if let _ = response.data(using: .ascii) {
            outputStream?.write(buff, maxLength: buff.count)
        }

//        let bytes: [UInt8] = [0,0,0,41,1,19,73,115,67,108,105,101,110,116,79,110,108,105,110,101,65,115,121,110,99,0,130,10,4,154,38,71,37,75,163,244,173,26,40,80,6,93,0,1,0]
//        outputStream?.write(bytes, maxLength: bytes.count)
    }

}
