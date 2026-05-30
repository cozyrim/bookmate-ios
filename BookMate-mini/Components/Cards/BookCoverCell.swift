import SwiftUI
import UIKit

struct BookCoverCell: View {
    var isSelected: Bool = false
    var imageName: String
    var width: CGFloat = 82
    
    private var height: CGFloat {
            width * 1.56
        }

        private var imageWidth: CGFloat {
            width * 0.77
        }

        private var imageHeight: CGFloat {
            height * 0.84
        }
    
    var body: some View {
        ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: width, height: height)
                    .shadow(color: .black.opacity(0.09), radius: 8, x: 0, y: 4)

                coverImage
                    .frame(width:imageWidth, height: imageHeight)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        .overlay{
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color("PeachRedHeavy") : Color.clear, lineWidth: 3)
        }
            .padding(.trailing, 12)
    }
    
    private var coverImage: some View {
        Group {
            if let url = URL(string: imageName),
               imageName.hasPrefix("http") {
                RemoteBookCoverImage(url: url)
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

private struct RemoteBookCoverImage: View {
    let url: URL
    @State private var loadedImage: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFit()
            } else if didFail {
                Image("책기본이미지")
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        loadedImage = nil
        didFail = false

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }

            loadedImage = image
        } catch {
            didFail = true
            print("커버 이미지 로딩 실패:", url.absoluteString, error.localizedDescription)
        }
    }
}

#Preview {
    BookCoverCell(isSelected: false, imageName: Book.dummyBooks[0].imageName)
}

