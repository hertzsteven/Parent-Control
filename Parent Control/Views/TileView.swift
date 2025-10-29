//
//  TileView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

struct TileView: View {
    let item: AppItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct TileView_Previews: PreviewProvider {
    static var previews: some View {
        TileView(
            item: AppItem(
                title: "Sample Tile Title",
                description: "This is a description for the app item to preview the layout and style.",
                iconName: "star.fill",
                additionalInfo: "Additional Info"
            ),
            onIncrease: {},
            onDecrease: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}

