//
//  StringUtils.swift
//  Pecker
//
//  Created by elanchou on 2024/12/10.
//

import UIKit

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
    
    func splitWithGrowingChunks(_ chunkSize: Int) -> [String] {
        guard chunkSize > 0, !self.isEmpty else { return [] }
        
        var chunks: [String] = []
        
        for i in stride(from: chunkSize, through: count, by: chunkSize) {
            let endIndex = index(startIndex, offsetBy: i, limitedBy: endIndex) ?? endIndex
            chunks.append(String(self[startIndex..<endIndex]))
        }
        
        return chunks
    }
}
