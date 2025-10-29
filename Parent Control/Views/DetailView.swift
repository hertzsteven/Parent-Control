//
//  DetailView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    let item: TileItem
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // White top bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .foregroundColor(.blue)
                .background(Color.white)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with icon and title
                        HStack(spacing: 16) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 24, weight: .bold))
                                
                                Text(item.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Information section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal)
                            
                            Text(item.additionalInfo)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

