//
//  PublicBookshelfView.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/10/26.
//

import SwiftUI

struct PublicBookshelfView: View {
    let targetUser: PublicUserResponse // 방명록 주인
    
    @State private var books: [Book] = []
    @State private var isLoading = true
    
    private let socialService = SocialAPIService()
    private let tokenStore = KeychainTokenStore()
        
    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            
            if isLoading {
                            ProgressView()
                        } else {
                            ScrollView {
                                                VStack(spacing: 20) {
                                                    // 1. 타 유저 프로필 헤더
                                                    VStack(spacing: 8) {
                                                        ProfileImageView(
                                                            imageName: "profileImage",
                                                            imageURLString: targetUser.profileImageUrl,
                                                            selectedImage: nil,
                                                            showsEditIcon: false
                                                        )
                                                        .frame(width: 80, height: 80)
                                                        
                                                        Text(targetUser.nickname)
                                                                                        .font(.title3)
                                                                                        .fontWeight(.bold)
                                                                                    Text("님의 책장")
                                                                                        .font(.subheadline)
                                                        
                                                                                        .foregroundStyle(Color("TextSecondary"))
                                                                                                                }
                                                                                                                .padding(.top, 20)
                                                                                                                
                                                                                                                Divider()
                                                    // 2. 공개된 책 목록
                                                                            if books.isEmpty {
                                                                                Text("아직 공개된 책이 없습니다.")
                                                                                    .padding(.top, 40)
                                                                                    .foregroundStyle(.gray)
                                                                            } else {
                                                                                LazyVStack(spacing: 16) {
                                                                                    ForEach(books, id: \.id) { book in
                                                                                        // 기존 책 리스트 컴포넌트 재사용 (BookRowView 등이 있다면 활용하세요!)
                                                                                        // 예시용 임시 카드 레이아웃:
                                                                                        VStack(alignment: .leading, spacing: 8) {
                                                                                            Text(book.title).font(.headline)
                                                                                            Text(book.author).font(.subheadline).foregroundStyle(.gray)
                                                                                            if let rating = book.rating {
                                                                                                Text(String(repeating: "⭐️", count: rating))
                                                                                            }
                                                                                            if let review = book.review, !review.isEmpty {
                                                                                                Text(review)
                                                                                                    .font(.caption)
                                                                                                    .italic()
                                                                                                    .foregroundStyle(Color("TextSecondary"))
                                                                                            }
                                                                                        }
                                                                                        .padding()
                                                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                                                        .background(Color("Surface").opacity(0.8))
                                                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                                                        .padding(.horizontal)
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            .navigationTitle(targetUser.nickname)
                                                            .navigationBarTitleDisplayMode(.inline)
                                                            .onAppear {
                                                                Task {
                                                                    await loadTargetUserBooks()
                                                                }
                                                            }
                                                        }
    
    
    private func loadTargetUserBooks() async {
            guard let token = tokenStore.load() else { return }
            do {
                books = try await socialService.fetchPublicBooks(token: token, userId: targetUser.id)
            } catch {
                print("타 유저 책장 조회 실패:", error)
            }
            isLoading = false
        }
    }

#Preview {
    NavigationStack {
        PublicBookshelfView(
            targetUser: PublicUserResponse(
                id: UUID(),
                nickname: "독서왕",
                profileImageUrl: nil
            )
        )
    }
}
