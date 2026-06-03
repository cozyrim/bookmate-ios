//
//  BookManualEntryView.swift
//  BookMate-mini
//
//  Created by 한채림 on 5/22/26.
//

import SwiftUI
import PhotosUI

struct BookManualEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var imageName = "책기본이미지"
    @State private var title = ""
    @State private var author = ""
    @State private var selectedCategory = "카테고리 선택"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedCoverImage: UIImage?
    @State private var previewDraft: BookRegistrationDraft?
    @ObservedObject var viewModel: BookMateViewModel
    private let initialDraft: BookRegistrationDraft?
    @Binding var selectedTab: Int
    
    private let categories = ["소설", "에세이", "인문", "자기계발", "과학", "기타"]
    private let coverWidth: CGFloat = 170
    private let coverHeight: CGFloat = 232
    private let coverCornerRadius: CGFloat = 26
    private let contentHorizontalPadding: CGFloat = 28
    private let headerTopPadding: CGFloat = 52
    private let bottomTabClearance: CGFloat = 96
    
    let onFinishRegistration: (Int) -> Void
    
    private var coverPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: coverCornerRadius)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: coverCornerRadius)
                        .strokeBorder(
                            Color.gray.opacity(0.45),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                }

            VStack(spacing: 12) {
                Image(systemName: "camera")
                    .font(.largeTitle)

                Text("커버 이미지 업로드")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color("TextMuted"))
        }
        .frame(width: coverWidth, height: coverHeight)
    }

    @ViewBuilder
    private var coverPickerContent: some View {
        if let selectedCoverImage {
            Image(uiImage: selectedCoverImage)
                .resizable()
                .scaledToFill()
                .frame(width: coverWidth, height: coverHeight)
                .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius))
        } else if let url = URL(string: imageName),
                  imageName.hasPrefix("http") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: coverCornerRadius)
                            .fill(.white)

                        ProgressView()
                    }

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    coverPlaceholder

                @unknown default:
                    coverPlaceholder
                }
            }
            .frame(width: coverWidth, height: coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: coverCornerRadius))
        } else {
            coverPlaceholder
        }
    }
    
    init(viewModel: BookMateViewModel, initialDraft: BookRegistrationDraft? = nil, selectedTab: Binding<Int>, onFinishRegistration: @escaping (Int) -> Void) {
        self.viewModel = viewModel
        self.initialDraft = initialDraft
        self._selectedTab = selectedTab
        // 검색 결과로 받은 책 정보를 새 책 등록 화면의 입력칸 초기값으로 넣어주는 코드
        self.onFinishRegistration = onFinishRegistration
        
        // swiftui가 상태 관리, 처음 값을 정할 때 상자 직접 만듦
        // 값을 보관하고 바뀐 값을 감시하고 화면을 다시 그림
        _title = State(initialValue: initialDraft?.title ?? "")
        _author = State(initialValue: initialDraft?.author ?? "")
        _imageName = State(initialValue: initialDraft?.imageName ?? "책기본이미지")
        _selectedCategory = State(initialValue: initialDraft?.category ?? "카테고리 선택")
    }
    
    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
            VStack(spacing: 12) {
                HStack{
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(Color("TextPrimary"))
                    }
                    Spacer()
                    Text("새 책 등록")
                        .font(.title)
                        .fontWeight(.semibold)
                    Spacer()
                    Color.clear
                        .frame(width: 28, height: 28)
                }
                .frame(height: 44)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    coverPickerContent
                        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
                        .padding(.top)
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        guard let data = try? await newItem?.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else {
                            return
                        }
                        
                        selectedCoverImage = image
                    }
                }
                
                VStack(alignment: .leading, spacing: 10){
                    Text("책 제목")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextSecondary"))
                        .padding(.horizontal, 4)
                    
                    ManualBookInputField(text: $title, placeholder: "제목을 입력하세요", iconName: "book.closed")
                }
                
                VStack(alignment: .leading, spacing: 10){
                    Text("저자")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextSecondary"))
                        .padding(.horizontal, 4)
                    
                    ManualBookInputField(text: $author, placeholder: "저자를 입력하세요", iconName: "book.closed")
                }
                
                VStack(alignment: .leading, spacing: 10){
                    Text("카테고리")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("TextSecondary"))
                        .padding(.horizontal, 4)
                    
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .foregroundStyle(Color("TextMuted"))
                            
                            Text(selectedCategory)
                                .foregroundStyle(selectedCategory == "카테고리 선택" ? .gray : .black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Color("TextMuted"))
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 58)
                        .background {
                            Capsule()
                                .fill(Color(.skyblue3))
                                .overlay{
                                    Capsule()
                                        .stroke(Color("Border").opacity(0.15), lineWidth: 1)
                                        .blur(radius: 2)
                                        .offset(y: 2)
                                        .mask(Capsule().fill(Color("TextPrimary")))
                                }
                        }
                    }
                }
                Spacer(minLength: 12)
                
                Button {
                    previewDraft = BookRegistrationDraft(
                        title: title,
                        author: author,
                        imageName: imageName,
                        category: selectedCategory
                        )
                } label: {
                    Label("등록하기", systemImage: "checkmark.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color("Primary"))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color("Shadow").opacity(0.06), radius: 7, x: 0, y: 2)
                }
                .navigationDestination(item: $previewDraft){ draft in
                    BookRegistrationPreviewView(
                        draft: draft,
                        viewModel: viewModel,
                        selectedTab: $selectedTab,
                        onFinishRegistration: { tab in
                            dismiss()
                            DispatchQueue.main.async {
                                onFinishRegistration(tab)
                            } // 나(BookManualEntryView)를 먼저 닫고,
                            // 부모에게 "이제 tab으로 이동해줘"라고 전달
                        }
                    )
                }
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.top, headerTopPadding)
            .padding(.bottom, bottomTabClearance)
        }
        
        .navigationBarBackButtonHidden(true)
    }
}




#Preview {
    BookManualEntryView(viewModel: BookMateViewModel(), selectedTab: .constant(0), onFinishRegistration: { _ in }
    )
}
