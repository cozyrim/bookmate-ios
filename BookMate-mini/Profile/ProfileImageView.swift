//
//  ProfileImageView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/23/26.
//

import SwiftUI
import UIKit

struct ProfileImageView: View {
    let imageName: String
    var imageURLString: String? = nil
    var selectedImage: UIImage? = nil
    var showsEditIcon: Bool = true
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        if let onTap {
            Button {
                onTap()
            } label: {
                imageContent
            }
            .buttonStyle(.plain)
        } else {
            imageContent
        }
    }
    
    private var imageContent: some View {
        ZStack(alignment: .bottomTrailing) {
            profileImage
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                                            .stroke(Color("Surface"), lineWidth: 5)
                }
                .shadow(color: Color("Shadow").opacity(0.08), radius: 12, x: 0, y: 6)
            
            if showsEditIcon {
                Image(systemName: "pencil")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color("TextSecondary"))
                                    .frame(width: 48, height: 48)
                                    .background(Color("Primary"))
                                    .clipShape(Circle())
                                    .overlay {
                                        Circle()
                                            .stroke(Color("Surface"), lineWidth: 4)
                                    }
                                    .shadow(color: Color("Primary").opacity(0.35), radius: 10, x: 0, y: 4)
                                    .offset(x: 10, y: 10)
            }
        }
    }
    @ViewBuilder
    private var profileImage: some View {
        if let selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
        } else if let imageURLString,
                  let url = URL(string: imageURLString),
                  url.isFileURL,
                  let uiImage = UIImage(contentsOfFile: url.path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let imageURLString,
                  imageURLString.hasPrefix("http"),
        let url = displayImageURL(from: imageURLString){
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                }
            }
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
        }
    }
    
    private func displayImageURL(from string: String) -> URL? {
        guard var components = URLComponents(string: string) else {
            return nil
        }

        if components.scheme == "http" {
            let host = components.host ?? ""

            let isLocalServer =
                host == "127.0.0.1" ||
                host == "localhost" ||
                host == "::1"

            if !isLocalServer {
                components.scheme = "https"
            }
        }

        return components.url
    }
    
    
}




    
#Preview {
    ProfileImageView(imageName: "profileImage")
}
