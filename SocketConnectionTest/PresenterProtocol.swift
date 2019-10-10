//
//  PresenterProtocol.swift
//  SocketConnectionTest
//
//  Created by Anastasia Markovets on 07/10/2019.
//  Copyright © 2019 Anastasia Markovets. All rights reserved.
//

import Foundation

protocol PresenterProtocol: class {
    
    func resetUIWithConnection(status: Bool)
    func updateStatusViewWith(status: String)
    func update(message: String)
}
