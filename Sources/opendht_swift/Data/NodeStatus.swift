//
//  File.swift
//  
//
//  Created by Eugene Antropov on 04.03.2023.
//

import Foundation

public enum NodeStatus: String {
    case disconnected  // 0 nodes
    case connecting   // 1+ nodes
    case connected // 1+ good nodes
}
