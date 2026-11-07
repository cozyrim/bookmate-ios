import SwiftUI
import Kingfisher

struct BookCoverCell: View {
    var isSelected: Bool = false
    var imageName: String
    var width: CGFloat = 82
    var trailingPadding: CGFloat = 12
    var showsBackground: Bool = false
    var coverCornerRadius: CGFloat = ReadingStyle.coverRadius
    
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
                    .clipShape(.rect(cornerRadius: coverCornerRadius))
                    .frame(width:imageWidth, height: imageHeight)
                    .shadow(color: Color("Shadow").opacity(0.10), radius: 3, x: 0, y: 2)
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
                RemoteBookCoverImage(
                    url: url,
                    targetSize: CGSize(width: imageWidth, height: imageHeight)
                )
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

private struct RemoteBookCoverImage: View {
    @Environment(\.displayScale) private var displayScale

    let url: URL
    let targetSize: CGSize

    var body: some View {
        KFImage(BookCoverSource.preferredURL(for: url))
            .alternativeSources(BookCoverSource.preferredURL(for: url) == url ? [] : [.network(ImageResource(downloadURL: url))])
            .setProcessor(
                DownsamplingImageProcessor(size: targetSize)
            )
            .scaleFactor(displayScale)
            .cacheOriginalImage()
            .placeholder {
                ProgressView()
            }
            .onFailureView {
                Image("책기본이미지")
                    .resizable()
                    .scaledToFit()
            }
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFit()
    }
}

#Preview {
    BookCoverCell(isSelected: false, imageName: Book.dummyBooks[0].imageName)
}
