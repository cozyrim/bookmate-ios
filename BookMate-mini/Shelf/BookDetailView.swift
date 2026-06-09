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
    @State private var readingStatus: ReadingStatus? = nil
    @FocusState private var isReviewFocused: Bool
    @State private var startDateText: String = "" // 시작 날짜 텍스트
    @State private var endDateText: String = ""   // 종료 날짜 텍스트
    
    // 다이어리 메모 전용 상태
    @State private var isShowingMemoAddSheet = false
    @State private var editingMemo: ReadingMemo? = nil
    
    // 구절 탭 전용 상태
    @State private var editingQuote: Quote? = nil
    @State private var isShowingQuoteAddSheet = false // 새 구절 시트 띄우기용
    
    
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
            self.readingStatus = book.readingStatus
            self.startDateText = book.startDate ?? ""
            self.endDateText = book.endDate ?? ""
            
            // 진입 시 이 책의 구절 데이터 로드
            Task {
                await viewModel.loadQuotes(bookId: book.id)
                await viewModel.loadReadingMemos(bookId: book.id)
            }
        }
        .sheet(item: $editingQuote) { quote in
            QuoteEditSheet(viewModel: viewModel, quote: quote)
        }
        .sheet(isPresented: $isShowingQuoteAddSheet) {
            QuoteAddSheet(viewModel: viewModel, bookId: book.id)
        }
        .sheet(isPresented: $isShowingMemoAddSheet) {
            ReadingMemoAddSheet(viewModel: viewModel, bookId: book.id)
        }
        .sheet(item: $editingMemo) { memo in
            ReadingMemoEditSheet(viewModel: viewModel, memo: memo)
        }
    }
    
    // MARK: - UI Components
    
    // 상단 책 정보 카드
    private var bookInfoCard: some View {
        HStack(alignment: .top, spacing: 0){
            BookCoverCell(imageName: book.imageName)
            
            VStack(alignment: .leading, spacing: 6){
                // 독서 상태 뱃지
                if let status = book.readingStatus {
                    Text(status.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Primary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("Primary").opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Text("\(book.title)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(book.author)")
                    .font(.caption)
                    .foregroundStyle(Color("TextMuted"))
                    .fontWeight(.bold)
                
                // 작성된 게 있을 때만 보임
                if let rating = book.rating, rating > 0 {
                    StarRatingView(rating: rating, isInteractive: false, starSize: 14)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bookmark")
                    Text("저장된 단어 \(savedWordsForBookCount)개")
                }
                .font(.caption2)
                .foregroundStyle(Color("PrimaryDeep"))
            }
            //            .frame(width: 200, height: 130, alignment: .leading)
            //            .padding(.leading, 24)
            //            .background(Color("Surface"))
            //            .clipShape(RoundedRectangle(cornerRadius: 36))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
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
                isShowingQuoteAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("새 구절 추가하기")
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color("Primary"))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color("Primary").opacity(0.1))
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
                                        .background(Color("Primary").opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                
                                Spacer()
                                
                                // 수정 버튼
                                Button {
                                    editingQuote = quote
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color("TextMuted"))
                                        .frame(width: 32, height: 32)
                                        .background(Color("Surface"))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                // 삭제 버튼
                                Button {
                                    Task { await viewModel.deleteQuote(quote) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.red.opacity(0.7))
                                        .frame(width: 32, height: 32)
                                        .background(Color("Surface"))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 36) {
            
            // 💡 [섹션 1] 다이어리 폼 (상태, 별점, 기간, 감상평)
            VStack(alignment: .leading, spacing: 24) {
                
                // 1-1. 독서 상태 선택
                VStack(alignment: .leading, spacing: 12) {
                    Text("독서 상태")
                        .font(.headline)
                        .foregroundStyle(Color("TextMuted"))
                    
                    HStack(spacing: 8) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Button {
                                // 이미 선택된 상태를 탭하면 해제(초기화)
                                readingStatus = (readingStatus == status) ? nil : status
                            } label: {
                                Text(status.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(readingStatus == status ? Color("Primary") : Color("Surface"))
                                    .foregroundStyle(readingStatus == status ? .white : Color("TextPrimary"))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(readingStatus == status ? Color.clear : Color("TextMuted").opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: readingStatus)
                        }
                    }
                }
                
                // 1-2. 별점 (이전 코드를 활용해 자연스럽게 배치)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("이 책, 어땠나요?")
                            .font(.headline)
                            .foregroundStyle(Color("TextMuted"))
                        
                        Spacer()
                        
                        // 별점 초기화 버튼
                        if rating > 0 {
                            Button {
                                rating = 0
                            } label: {
                                Text("초기화")
                                    .font(.caption)
                                    .foregroundStyle(Color("TextMuted"))
                            }
                        }
                    }
                    
                    StarRatingView(rating: rating, isInteractive: true, starSize: 32) { newRating in
                        self.rating = newRating
                    }
                }
                
                // 1-3. 읽은 기간
                VStack(alignment: .leading, spacing: 12) {
                    Text("읽은 기간")
                        .font(.headline)
                        .foregroundStyle(Color("TextMuted"))
                    
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color("Primary"))
                        
                        TextField("시작일 (예: 26.01.01)", text: $startDateText)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        
                        Text("~")
                            .foregroundStyle(Color("TextMuted"))
                        
                        TextField("종료일 (예: 26.01.10)", text: $endDateText)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("TextMuted").opacity(0.15), lineWidth: 1)
                    )
                }
                // 1-4. 나만의 감상평
                VStack(alignment: .leading, spacing: 12) {
                    Text("나만의 감상평")
                        .font(.headline)
                        .foregroundStyle(Color("TextMuted"))
                    
                    TextEditor(text: $reviewText)
                        .focused($isReviewFocused)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(minHeight: 140)
                        .background(Color("Surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color("TextMuted").opacity(0.15), lineWidth: 1)
                        )
                }
                // 1-5. 다이어리 폼 전체 저장 버튼
                Button {
                    isReviewFocused = false // 키보드 내리기
                    Task {
                        _ = await viewModel.saveRatingAndReview(
                            book: book,
                            rating: rating,
                            review: reviewText,
                            readingStatus: readingStatus,
                            startDate: startDateText,
                            endDate: endDateText
                        )
                    }
                } label: {
                    Text("다이어리 한 번에 저장하기")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("Primary"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color("Primary").opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            
            // 구분선으로 위아래 섹션 부드럽게 분리
            Divider()
                .padding(.horizontal, 24)
            
            // 💡 [섹션 2] 독서 타임라인 (메모)
            VStack(alignment: .leading, spacing: 20) {
                // 타임라인 헤더
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("독서 타임라인")
                            .font(.headline)
                        Text("책을 읽으며 남긴 조각들")
                            .font(.caption)
                            .foregroundStyle(Color("TextMuted"))
                    }
                    
                    Spacer()
                    
                    // 새 메모 추가 버튼 (캡슐 형태)
                    Button {
                        // TODO: 나중에 실제 메모 추가 시트로 연결될 부분
//                        let dummyMemo = ReadingMemo(bookId: book.id, date: "2026-01-\(Int.random(in: 16...30))", page: Int.random(in: 10...150), text: "여우와의 대화 장면이 인상적. 여기에 메모가 들어갑니다!")
                        isShowingMemoAddSheet = true
//                        viewModel.addReadingMemo(dummyMemo)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("메모 남기기")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color("Primary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("Primary").opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                let memos = viewModel.savedMemos(for: book.id)
                
                // 메모가 없을 때의 Empty State UI
                if memos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.largeTitle)
                            .foregroundStyle(Color("TextMuted").opacity(0.5))
                        Text("아직 작성된 메모가 없어요.")
                            .font(.subheadline)
                            .foregroundStyle(Color("TextMuted"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(Color("Surface"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("TextMuted").opacity(0.15), lineWidth: 1)
                    )
                } else {
                    // 메모가 있을 때의 타임라인 렌더링
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(memos) { memo in
                            HStack(alignment: .top, spacing: 16) {
                                
                                // 왼쪽 타임라인 그래픽 (점과 선)
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(Color("Primary"))
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color("AppBackground"), lineWidth: 3) // 배경색 겹쳐서 도넛 느낌
                                        )
                                        .padding(.top, 4)
                                    
                                    // 마지막 메모가 아니면 선 긋기
                                    if memo.id != memos.last?.id {
                                        Rectangle()
                                            .fill(Color("Primary").opacity(0.3))
                                            .frame(width: 2)
                                            .padding(.top, 4)
                                    }
                                }
                                
                                // 메모 우측 내용 영역
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("\(memo.date)")
                                            .font(.caption.bold())
                                            .foregroundStyle(Color("Primary"))
                                        
                                        if let page = memo.page {
                                            Text("· p.\(page)")
                                                .font(.caption)
                                                .foregroundStyle(Color("TextMuted"))
                                        }
                                        
                                        Spacer()
                                        
                                        // 더보기 메뉴 (수정/삭제)
                                        Menu {
                                            Button("수정", action: { /* TODO: 수정 기능 */ })
                                            Button("삭제", role: .destructive, action: {
                                                Task { await viewModel.deleteReadingMemo(memo) }
                                                })
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .foregroundStyle(Color("TextMuted"))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                    
                                    Text(memo.text)
                                        .font(.body)
                                        .lineSpacing(4)
                                        .padding(.bottom, 28) // 항목 간 간격 띄우기
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}



#Preview {
    BookDetailView(viewModel: BookMateViewModel(), book: Book.dummyBooks[0])
}
