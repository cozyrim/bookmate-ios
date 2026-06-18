//
//  BookRegistrationCompleteView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

struct BookRegistrationCompleteView: View {
    @ObservedObject var viewModel: BookMateViewModel
    let draft: BookRegistrationDraft
    let book: Book
    @Binding var selectedTab: Int
    let onFinishRegistration: (Int) -> Void
    @ViewBuilder // 여러 종류의 View를 조건에 따라 반환할 수 있게 해주는 도구
    
    
    private var coverImage: some View{
        if let url = URL(string: book.imageName),
            book.imageName.hasPrefix("http") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                    
                case .failure:
                    fallbackCover
                    
                @unknown default:
                    fallbackCover
                }
            }
        } else{
            Image(book.imageName)
                .resizable()
                .scaledToFill()
        }
    }
    
    private var fallbackCover: some View {
        ZStack{
            RoundedRectangle(cornerRadius: 30)
                .fill(Color("SurfaceSoft"))
            
            Image(systemName: "book.closed")
                .font(.largeTitle)
                            .foregroundStyle(Color("TextMuted"))
        }
    }
    
    
    
    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            

            VStack(spacing: 12){
                ZStack{
                    Circle()
                        .fill(Color("SuccessSoft"))
                                .frame(width: 100, height: 100)
                                .shadow(color: Color("Success").opacity(0.08), radius: 10)
                    
                    
                    Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Color("Success"))
                }
                .padding(.bottom)
                
                Text("책 등록 완료")
                    .font(.title)
                
                Text("성공적으로 내 책장에 책이 등록되었습니다.")
                    .font(.callout)
                    .foregroundStyle(Color("TextSecondary").opacity(0.9))
                
                coverImage
                    .frame(width: 170, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding()
                
                VStack(spacing: 12){
                    Button{
                        viewModel.searchMode = .dictionary
                        viewModel.searchText = ""
                        onFinishRegistration(0)
                    } label: {
                        Label("단어 검색 시작하기", systemImage: "magnifyingglass")
                            .font(.callout)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color("Primary"))
                            .foregroundStyle(Color("PrimaryButtonText"))
                            .clipShape(Capsule())
                            .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
                    }
                    Button{
                        onFinishRegistration(1)
                    } label: {
                        Text("내 책장으로 이동")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color(.black).opacity(0.02))
                            .foregroundStyle(Color("TextPrimary"))
                            .clipShape(Capsule())
                            .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    BookRegistrationCompleteView(
        viewModel: BookMateViewModel(),
        
        draft: BookRegistrationDraft(
            title: "미움받을 용기",
            author: "기시미 이치로",
            imageName: "책기본이미지",
            category: "인문"
        ),
        book: Book.dummyBooks[0],
        selectedTab: .constant(0),
        onFinishRegistration: { _ in }
    )
}
