import SwiftUI

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
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                        
                    case .failure:
                        Image(systemName: "book.closed")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                }
            } else {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            }
        }
    }
}

#Preview {
    BookCoverCell(isSelected: false, imageName: Book.dummyBooks[0].imageName)
}


