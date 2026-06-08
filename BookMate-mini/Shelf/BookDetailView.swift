//
//  BookDetailView.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

enum BookDetailTab: String, CaseIterable {
    case words = "단어"
    case quotes = "구절"
    case diary = "다이어리"
}


struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel
    
    let book: Book // 어떤 책인지
    
    // 탭 상태
    @State private var selectedTab: BookDetailTab = .words
    
    // 단어 탭 전용 상태
    @State private var bookWordSearchText = ""
    
    // 다이어리 탭 전용 상태
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @FocusState private var isReviewFocused: Bool
    
    
    // MARK: - Computed Properties
    
    private var savedWordsForBookCount: Int {
        viewModel.savedWords(for: book.id).count
    }
    
    private var filteredWordsForBook: [Word] {
        let words = viewModel.savedWords(for: book.id)
        let trimmed = bookWordSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let filtered = trimmed.isEmpty ? words : words.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
            || word.meaning.localizedCaseInsensitiveContains(trimmed)
            || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }
        return Array(filtered.reversed())
    } // 현재 책 id와 같은 bookId를 가진 단어만 가져옴
    
    private var  savedQuotesForBook: [Quote] {
        viewModel.savedQuotes(for: book.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack{
            Color("AppBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 24){
                HStack {
                    CircleIconButton(systemName: "chevron.left") {
                        dismiss()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top) //?
                .padding(.bottom, 16) //?
                
                // 본문 스크롤
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        bookInfoCard
                        
                        tabBar
                        
                        // 탭에 따른 화면 전환
                        switch selectedTab {
                        case .words:
                            wordsTabContent
                        case .quotes:
                            quotesTabContent
                        case .diary:
                            diaryTabContent
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // 다이어리 탭의 초기값 세팅
            self.rating = book.rating ?? 0
            self.reviewText = book.review ?? ""
            
            // 진입 시 이 책의 구절 데이터 로드
            Task {
                await viewModel.loadQuotes(bookId: book.id)
            }
        }
    }
    
    // MARK: - UI Components
    
    // 상단 책 정보 카드
    private var bookInfoCard: some View {
        HStack{
            BookCoverCell(imageName: book.imageName)
            
            VStack(alignment: .leading, spacing: 12){
                Text("\(book.title)")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("\(book.author)")
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))
                    .fontWeight(.bold)
                
                // 작성된 게 있을 때만 보임
                if let rating = book.rating, rating > 0 {
                    StarRatingView(rating: rating, isInteractive: false, starSize: 14)
                }
                
                HStack{
                    Image(systemName: "bookmark")
                    Text("저장된 단어 \(savedWordsForBookCount)개")
                }
                .font(.caption2)
                .foregroundStyle(Color("PrimaryDeep"))
            }
            .frame(width: 200, height: 130, alignment: .leading)
            .padding(.leading, 24)
            .background(Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 36))
        }
    }
    
    // 커스텀 탭 바 디자인
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BookDetailTab.allCases, id: \.self) { tab in
                VStack(spacing: 8) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .bold : .medium)
                        .foregroundStyle(selectedTab == tab ? Color("PrimaryDeep") : Color("TextMuted"))
                    
                    Rectangle()
                        .fill(selectedTab == tab ? Color("PrimaryDeep") : Color.clear)
                        .frame(height: 2)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // 단어 탭
    private var wordsTabContent: some View {
        VStack(spacing: 24) {
            SearchTextField(searchText: $bookWordSearchText, placeholder: "이 책에서 단어 검색...")
                .padding(.horizontal, 24)
            
            HStack{
                Text("최근 추가됨")
                Spacer()
                Text("최신순")
            }
            .font(.subheadline)
            .foregroundStyle(Color("TextMuted"))
            .padding(.horizontal, 24)
            
            if filteredWordsForBook.isEmpty {
                ContentStateView(
                    type: .empty,
                    iconName: "magnifyingglass",
                    title: bookWordSearchText.isEmpty ? "저장한 단어가 없어요." : "검색 결과가 없어요.",
                    message: bookWordSearchText.isEmpty ? "이 책에서 만난 단어를 저장해보세요." : "다른 단어로 다시 검색해보세요.",
                    buttonTitle: nil,
                    buttonIconName: nil,
                    buttonAction: nil
                )
                .padding(.horizontal, 24)
            } else {
                ForEach(filteredWordsForBook) { word in
                    NavigationLink{
                        WordDetailsView(viewModel: viewModel, word: word)
                    } label: {
                        BookSavedWordCell(text: word.text, partOfSpeech: word.partOfSpeech, meaning: word.meaning)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    

    
    // 구절 탭
    private var quotesTabContent: some View {
        VStack(spacing: 16) {
            // 새 구절 추가 버튼 ( 추후 시트 연결용)
            Button {
                // TODO: 구절 추가 시트 연결 액션
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("새 구절 추가하기")
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color("Primary"))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color("PrimaryLight"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            if savedQuotesForBook.isEmpty {
                ContentStateView(
                    type: .empty,
                    iconName: "quote.bubble",
                    title: "저장된 구절이 없어요.",
                    message: "기억하고 싶은 문장을 기록해보세요.",
                    buttonTitle: nil, buttonIconName: nil, buttonAction: nil
                )
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 16) {
                    ForEach(savedQuotesForBook) { quote in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\"\(quote.text)\"")
                                .font(.body)
                                .fontWeight(.medium)
                                .lineSpacing(4)
                            
                            HStack {
                                if let page = quote.page {
                                    Text("p.\(page)")
                                        .font(.caption)
                                        .foregroundStyle(Color("PrimaryDeep"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color("PrimaryLight"))
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                if let memo = quote.memo, !memo.isEmpty {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(Color("TextMuted"))
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color("Surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    // 다이어리 탭
    private var diaryTabContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 1. 별점 입력
            VStack(alignment: .leading, spacing: 12) {
                Text("이 책, 어땠나요?")
                    .font(.headline)
                
                // 기존에 만들어두신 StarRatingView를 활용합니다!
                StarRatingView(rating: rating, isInteractive: true, starSize: 32) { newRating in
                    self.rating = newRating
                }
            }
            .padding(.horizontal, 24)
            
            // 2. 감상평 작성
            VStack(alignment: .leading, spacing: 12) {
                Text("나만의 감상평")
                    .font(.headline)
                
                TextEditor(text: $reviewText)
                    .focused($isReviewFocused)
                    .scrollContentBackground(.hidden) // 배경 투명화 처리
                    .padding(16)
                    .frame(minHeight: 200)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color("TextMuted").opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)
            
            // 3. 다이어리 저장 버튼
            Button {
                isReviewFocused = false // 키보드 내리기
                Task {
                    _ = await viewModel.saveRatingAndReview(book: book, rating: rating, review: reviewText)
                }
            } label: {
                Text("다이어리 저장하기")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("Primary"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}





#Preview {
    BookDetailView(viewModel: BookMateViewModel(), book: Book.dummyBooks[0])
}
