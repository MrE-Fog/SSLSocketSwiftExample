//
//  DataSocket.swift
//  SocketConnectionTest
//
//  Created by Anastasia Markovets on 07/10/2019.
//  Copyright © 2019 Anastasia Markovets. All rights reserved.
//

import Foundation

struct DataSocket {
    
    let ipAddress: String!
    let port: Int!
    
    init(ip: String, port: String){        
        self.ipAddress = ip
        self.port      = Int(port)
    }
}
