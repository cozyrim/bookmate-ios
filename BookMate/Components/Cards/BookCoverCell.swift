import SwiftUI
import UIKit

struct BookCoverCell: View {
    var isSelected: Bool = false
    var imageName: String
    var width: CGFloat = 82
    var trailingPadding: CGFloat = 12
    var showsBackground: Bool = true
    
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
            if showsBackground {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("SurfaceSoft"))
                    .frame(width: width, height: height)
                    .shadow(color: Color("Shadow").opacity(0.09), radius: 8, x: 0, y: 4)
            }

                coverImage
                    .frame(width:imageWidth, height: imageHeight)
                    .shadow(color: Color("Shadow").opacity(0.2), radius: 4, x: 0, y: 2)
            }
        .frame(
            width: showsBackground ? width : imageWidth,
            height: showsBackground ? height : imageHeight
        )
        .overlay{
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color("PrimaryDeep") : Color.clear, lineWidth: 3)
        }
            .padding(.trailing, trailingPadding)
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
            if Task.isCancelled || isCancelledImageRequest(error) {
                return
            }

            didFail = true
            DebugLogger.log("커버 이미지 로딩 실패:", url.absoluteString, error.localizedDescription)
        }
    }

    private func isCancelledImageRequest(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

#Preview {
    BookCoverCell(isSelected: false, imageName: Book.dummyBooks[0].imageName)
}
