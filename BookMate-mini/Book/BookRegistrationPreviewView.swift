//
//  BookRegistrationPreviewView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI

// 책을 선택한 뒤, 최종 등록 전에 “이 책으로 등록하기”를 보여주는 확인 화면
struct BookRegistrationPreviewView: View {
    @Environment(\.dismiss) var dismiss
    let draft: BookRegistrationDraft
    @ObservedObject var viewModel: BookMateViewModel
    
    @Binding var selectedTab: Int
    @State private var savedBook: Book?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let onFinishRegistration: (Int) -> Void
    
    @ViewBuilder // 여러 종류의 View를 조건에 따라 반환할 수 있게 해주는 도구
    private var coverImage: some View{
        if let url = URL(string: draft.imageName),
            draft.imageName.hasPrefix("http") {
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
            Image(draft.imageName)
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
        ZStack(alignment: .top) {
            Color("AppBackgroundSoft")
                .ignoresSafeArea()
            
            Color("AppBackground")
                .frame(height: 130)
                .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                HStack {
                    CircleIconButton(systemName: "chevron.left") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("북메이트")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
//                    Button {
//                                            
//                                        } label: {
//                                            Text("수정")
//                                                .fontWeight(.semibold)
//                                                .foregroundStyle(Color("PrimaryDeep"))
//                                        }
                }
                .padding(.horizontal, 24)
                .frame(height: 90)
                .background(Color("AppBackground"))
                
                ScrollView {
                    VStack(spacing: 6) {
                        coverImage
//                            .frame(width: 200, height: 260)
                            .frame(width: 165, height: 225)
//                            .frame(width: 180, height: 275)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .padding(.bottom)


                        Text(draft.title)
                                .font(.title)
                                .fontWeight(.semibold)
                            
                        Text(draft.author)
                                .font(.callout)
                                .foregroundStyle(Color("TextSecondary"))
                        
                        VStack{
                            Text(draft.contents.isEmpty ? "책 소개가 제공되지 않습니다.": draft.contents)
                        }
                        .font(.callout)
                        .foregroundStyle(Color("TextSecondary").opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color("Surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .shadow(color: Color("Primary").opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding()
                    }
                    .padding()

                    Button {
                        Task {
                            isSaving = true
                            
                            do {
                                savedBook = try await viewModel.registerBook(draft: draft)
                            } catch {
                                errorMessage = "책 등록에 실패했습니다."
                                print("책 등록 실패:", error)
                            }
                            isSaving = false
                        }
                    } label: {
                        Text(isSaving ? "저장 중..." : "이 책으로 등록하기")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color("Primary"))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Color("Error"))
                    }
                    
                    
                    // 여기서 draft는 아직 서버 저장 전의 임시 책 정보,
                    // book은 서버에 저장이 끝난 진짜 책장 책 정보
                
                }
                .navigationDestination(item: $savedBook) { book in
                    BookRegistrationCompleteView(
                        viewModel: viewModel,
                        draft: draft,
                        book: book,
                        selectedTab: $selectedTab,
                        onFinishRegistration: { tab in
                            dismiss()
                            DispatchQueue.main.async {
                                onFinishRegistration(tab)
                            }
                        }
                    )
                }
                .padding(.top,)
                .padding()
            }
            
        }
        
        .navigationBarBackButtonHidden(true)
        
    }
}

#Preview {
    BookRegistrationPreviewView(
            draft: BookRegistrationDraft(
                title: "미움받을 용기",
                author: "기시미 이치로",
                imageName: "책기본이미지",
                category: "인문"
            ),
            viewModel: BookMateViewModel(),
            selectedTab: .constant(0),
            onFinishRegistration: { _ in }
        )
}
