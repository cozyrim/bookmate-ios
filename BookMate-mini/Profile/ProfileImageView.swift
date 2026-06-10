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
    var size: CGFloat = 112 // 👉 크기 파라미터 추가! 기본값은 112
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
                .frame(width: size, height: size) // 👉 고정된 112 대신 size 변수 사용
                .clipShape(RoundedRectangle(cornerRadius: size / 4))
                .overlay {
                    RoundedRectangle(cornerRadius: size / 4)
                        .stroke(Color("Surface"), lineWidth: size > 60 ? 5 : 2) // 작을 땐 테두리도 얇게
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
