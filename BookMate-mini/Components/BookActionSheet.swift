//
//  BookActionSheet.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import Foundation

enum BookActionSheet: Identifiable {
    case options(Book)
    case edit(Book)
    case progress(Book)
    
    var id: String {
        switch self {
        case .options(let book):
            return "options-\(book.id.uuidString)"
        case .edit(let book):
                    return "edit-\(book.id.uuidString)"
        case .progress(let book):
                    return "progress-\(book.id.uuidString)"
        }
    }
}
