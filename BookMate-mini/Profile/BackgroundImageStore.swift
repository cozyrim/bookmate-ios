//
//  BackgroundImageStore.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/2/26.
//

import Foundation
import UIKit

enum BackgroundImageStoreError: Error {
    case invalidImageData
    case missingDocumentsDirectory
}

//saveImageData
//→ PhotosPicker에서 받은 Data를 UIImage로 변환
//→ JPEG Data로 다시 변환
//→ Documents/custom-background.jpg에 저장
//→ 파일 이름 반환

enum BackgroundImageStore {
    static func saveImageData(_ data: Data) throws -> String {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw BackgroundImageStoreError.invalidImageData
        }
        
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw BackgroundImageStoreError.missingDocumentsDirectory
        }
        
        let fileName = "custom-background.jpg"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        try jpegData.write(to: fileURL, options: .atomic)
        
        return fileName
    }
    
    static func loadImage(fileName: String) -> UIImage? {
        guard !fileName.isEmpty,
              let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
              ).first else {
            return nil
        }
        
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    static func deleteImage(fileName: String) {
        guard !fileName.isEmpty,
              let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
              ).first else {
            return
        }
        let fileURL = documentsURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
