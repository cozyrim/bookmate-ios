//
//  ProfileMenuItem.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import Foundation

struct ProfileMenuItem: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    var isDestructive: Bool = false
    var showChevron: Bool = true
}

