//
//  BookDetailView.swift
//  BookMate
//
//  Created by 한채림 on 5/14/26.
//

import SwiftUI

enum BookDetailTab: String, CaseIterable {
    case words = "단어"
    case quotes = "문장"
    case diary = "다이어리"
}


struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BookMateViewModel

    let book: Book // 어떤 책인지
    private let initialTab: BookDetailTab
    private let opensMemoComposerOnAppear: Bool

    // 탭 상태
    @State private var selectedTab: BookDetailTab

    // 단어 탭 전용 상태
    @State private var bookWordSearchText = ""
    @State private var bookWordSortOrder: BookMateViewModel.ArchiveSortOrder = .latest
    @State private var isShowingBookWordSortOrder = false

    // 다이어리 탭 전용 상태
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var readingStatus: ReadingStatus? = nil
    @FocusState private var isReviewFocused: Bool
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isShowingReadingPeriodPicker = false

    // 다이어리 메모 전용 상태
    @State private var isShowingMemoAddSheet = false
    @State private var editingMemo: ReadingMemo? = nil
    @State private var didApplyInitialTab = false
    @State private var didOpenInitialMemoComposer = false

    // 문장 탭 전용 상태
    @State private var editingQuote: Quote? = nil
    @State private var isShowingQuoteAddSheet = false // 새 문장 시트 띄우기용
    @State private var isReviewPublic: Bool = false
    @State private var quoteToDelete: Quote?
    @State private var isShowingQuoteDeleteAlert = false

    init(
        viewModel: BookMateViewModel,
        book: Book,
        initialTab: BookDetailTab = .words,
        opensMemoComposerOnAppear: Bool = false
    ) {
        self.viewModel = viewModel
        self.book = book
        self.initialTab = initialTab
        self.opensMemoComposerOnAppear = opensMemoComposerOnAppear
        _selectedTab = State(initialValue: initialTab)
    }

    // MARK: - Computed Properties

    private var savedWordsForBookCount: Int {
        viewModel.savedWords(for: book.id).count
    }

    private var filteredWordsForBook: [Word] {
        let words = sortedWordsForBook(viewModel.savedWords(for: book.id))
        let trimmed = bookWordSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = trimmed.isEmpty ? words : words.filter { word in
            word.text.localizedCaseInsensitiveContains(trimmed)
            || word.meaning.localizedCaseInsensitiveContains(trimmed)
            || word.partOfSpeech.localizedCaseInsensitiveContains(trimmed)
        }
        return filtered
    } // 현재 책 id와 같은 bookId를 가진 단어만 가져옴

    private func sortedWordsForBook(_ words: [Word]) -> [Word] {
        switch bookWordSortOrder {
        case .latest:
            return words
        case .oldest:
            return Array(words.reversed())
        case .alphabetical:
            return words.sorted {
                $0.text.localizedStandardCompare($1.text) == .orderedAscending
            }
        }
    }

    private var  savedQuotesForBook: [Quote] {
        viewModel.savedQuotes(for: book.id)
    }

    private func applyMyReviewToForm() {
        let myReview = viewModel.myReview(for: book.id)

        rating = myReview?.rating ?? book.rating ?? 0
        reviewText = myReview?.content ?? book.review ?? ""
        isReviewPublic = myReview?.isPublic ?? false
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
        .enableSwipeBackGesture()
        .onAppear {
            PerformanceLogger.event("BookDetailAppear")

            if !didApplyInitialTab {
                didApplyInitialTab = true
                selectedTab = initialTab
            }

            // 다이어리 탭의 초기값 세팅
            applyMyReviewToForm()
            self.readingStatus = book.readingStatus
            self.startDate = BookMateDateFormatter.date(from: book.startDate)
            self.endDate = BookMateDateFormatter.date(from: book.endDate)

            if opensMemoComposerOnAppear && !didOpenInitialMemoComposer {
                didOpenInitialMemoComposer = true
                selectedTab = .diary

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isShowingMemoAddSheet = true
                }
            }

            // 진입 시 이 책의 문장 데이터 로드
            Task {
                await viewModel.loadMyReview(bookId: book.id)
                applyMyReviewToForm()
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
        .sheet(isPresented: $isShowingReadingPeriodPicker) {
            ReadingPeriodPickerSheet(startDate: $startDate, endDate: $endDate)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingBookWordSortOrder) {
            SortOrderSheet(
                currentOrder: bookWordSortOrder,
                onSelect: { selectedOrder in
                    bookWordSortOrder = selectedOrder
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .alert("문장을 삭제할까요?", isPresented: $isShowingQuoteDeleteAlert) {
            Button("취소", role: .cancel) {
                quoteToDelete = nil
            }

            Button("삭제", role: .destructive) {
                guard let quote = quoteToDelete else { return }
                quoteToDelete = nil

                Task {
                    await viewModel.deleteQuote(quote)
                }
            }
        } message: {
            Text("삭제한 문장은 되돌릴 수 없어요.")
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
                    ReadingStatusBadge(
                        status: status,
                        font: .caption2,
                        fontWeight: .semibold,
                        horizontalPadding: 8,
                        verticalPadding: 3
                    )
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
                Text("저장한 단어")
                Spacer()

                Button {
                    isShowingBookWordSortOrder = true
                } label: {
                    HStack(spacing: 6) {
                        Text(bookWordSortOrder.rawValue)

                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("TextMuted"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color("SurfaceElevated").opacity(0.72))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
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



    // 문장 탭
    private var quotesTabContent: some View {
        VStack(spacing: 14) {
            quotesHeaderCard

            if savedQuotesForBook.isEmpty {
                quoteEmptyCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(savedQuotesForBook) { quote in
                        quoteCard(quote)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var quotesHeaderCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("Primary"))
                .frame(width: 42, height: 42)
                .background(Color("Primary").opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("문장 보관함")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text(savedQuotesForBook.isEmpty ? "기억하고 싶은 문장을 바로 남겨보세요." : "\(savedQuotesForBook.count)개의 문장을 모아두었어요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isShowingQuoteAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("PrimaryButtonText"))
                    .frame(width: 38, height: 38)
                    .background(Color("Primary"), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("새 문장 추가하기")
        }
        .padding(16)
        .background(Color("Surface").opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color("Border").opacity(0.28), lineWidth: 1)
        }
        .padding(.horizontal, 24)
    }

    private var quoteEmptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "text.quote")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Color("Primary").opacity(0.7))
                .frame(width: 72, height: 72)
                .background(Color("Primary").opacity(0.1), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(spacing: 6) {
                Text("아직 저장된 문장이 없어요.")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("마음에 남은 문장을 페이지와 함께 남겨두면 다시 읽기 쉬워요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }

            Button {
                isShowingQuoteAddSheet = true
            } label: {
                Label("첫 문장 남기기", systemImage: "plus.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Primary"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color("Primary").opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color("Surface").opacity(0.86), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color("Border").opacity(0.26), lineWidth: 1)
        }
        .padding(.horizontal, 24)
    }

    private func quoteCard(_ quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color("Primary").opacity(0.72))
                    .padding(.top, 2)

                Text(quote.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color("TextPrimary").opacity(0.88))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let memo = quote.memo, !memo.isEmpty {
                Text(memo)
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("AppBackground").opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 8) {
                if let page = quote.page {
                    Label("p.\(page)", systemImage: "book")
                        .font(.caption.bold())
                        .foregroundStyle(Color("PrimaryDeep"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color("Primary").opacity(0.1), in: Capsule())
                }

                Spacer()

                Button {
                    editingQuote = quote
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("TextSecondary"))
                        .frame(width: 34, height: 34)
                        .background(Color("SurfaceElevated").opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("문장 수정")

                Button {
                    quoteToDelete = quote
                    isShowingQuoteDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("Error").opacity(0.78))
                        .frame(width: 34, height: 34)
                        .background(Color("SurfaceElevated").opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("문장 삭제")
            }
        }
        .padding(18)
        .background(Color("Surface").opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color("Border").opacity(0.22), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.035), radius: 10, x: 0, y: 4)
    }
    // 다이어리 탭
    private var diaryTabContent: some View {
        VStack(spacing: 16) {
            diarySummaryCard
            diaryEntryCard
            readingTimelineSection
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private var diarySummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "book.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color("Primary"))
                    .frame(width: 42, height: 42)
                    .background(Color("Primary").opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("내 독서 다이어리")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))

                    Text("상태, 감상평, 메모를 한곳에서 관리해요.")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                }

                Spacer()

                Button {
                    isShowingMemoAddSheet = true
                } label: {
                    Label("메모", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Primary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("Primary").opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: book.progress)
                    .tint(Color("Primary"))

                HStack {
                    Text("\(Int(book.progress * 100))% 읽음")
                        .font(.caption.bold())
                        .foregroundStyle(Color("PrimaryDeep"))

                    Spacer()

                    if let readingStatus {
                        ReadingStatusBadge(
                            status: readingStatus,
                            font: .caption,
                            fontWeight: .bold,
                            horizontalPadding: 10,
                            verticalPadding: 5
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(Color("Surface").opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color("Border").opacity(0.26), lineWidth: 1)
        }
    }

    private var diaryEntryCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text("독서 기록")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("필요한 것만 가볍게 채워도 괜찮아요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }

            diaryReadingStatusPicker
            diaryRatingPicker
            diaryPeriodPicker
            diaryReviewEditor
            diaryPublicToggle
            diarySaveButton
        }
        .padding(18)
        .background(Color("Surface").opacity(0.9), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color("Border").opacity(0.22), lineWidth: 1)
        }
        .shadow(color: Color("Shadow").opacity(0.035), radius: 10, x: 0, y: 4)
    }

    private var diaryReadingStatusPicker: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            diaryFieldTitle("독서 상태", systemImage: "flag")

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    Button {
                        readingStatus = readingStatus == status ? nil : status
                    } label: {
                        let isSelected = readingStatus == status

                        Text(status.displayName)
                            .font(.caption.bold())
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(isSelected ? status.badgeBackgroundColor : Color("AppBackground").opacity(0.72))
                            .foregroundStyle(isSelected ? status.badgeForegroundColor : Color("TextPrimary"))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(isSelected ? status.badgeForegroundColor.opacity(0.35) : Color("Border").opacity(0.32), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var diaryRatingPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                diaryFieldTitle("이 책, 어땠나요?", systemImage: "star")

                Spacer()

                if rating > 0 {
                    Button("초기화") {
                        rating = 0
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color("TextMuted"))
                }
            }

            StarRatingView(rating: rating, isInteractive: true, starSize: 30) { newRating in
                self.rating = newRating
            }
        }
    }

    private var diaryPeriodPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            diaryFieldTitle("읽은 기간", systemImage: "calendar")

            Button {
                isShowingReadingPeriodPicker = true
            } label: {
                HStack(spacing: 10) {
                    Text(BookMateDateFormatter.displayString(from: startDate))
                        .foregroundStyle(startDate == nil ? Color("TextMuted") : Color("TextPrimary"))

                    Text("~")
                        .foregroundStyle(Color("TextMuted"))

                    Text(BookMateDateFormatter.displayString(from: endDate))
                        .foregroundStyle(endDate == nil ? Color("TextMuted") : Color("TextPrimary"))

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color("TextMuted"))
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color("AppBackground").opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color("Border").opacity(0.26), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var diaryReviewEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            diaryFieldTitle("나만의 감상평", systemImage: "square.and.pencil")

            ZStack(alignment: .topLeading) {
                if reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("이 책을 읽고 남기고 싶은 감정이나 생각을 적어보세요.")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextMuted").opacity(0.72))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $reviewText)
                    .focused($isReviewFocused)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(minHeight: 138)
            }
            .background(Color("AppBackground").opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color("Border").opacity(0.24), lineWidth: 1)
            }
        }
    }

    private var diaryPublicToggle: some View {
        Toggle(isOn: $isReviewPublic) {
            VStack(alignment: .leading, spacing: 4) {
                Text("리뷰 공개")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("공개하면 다른 사용자가 이 책의 리뷰를 볼 수 있어요.")
                    .font(.caption)
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: Color("Primary")))
        .padding(14)
        .background(Color("AppBackground").opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var diarySaveButton: some View {
        Button {
            saveDiary()
        } label: {
            Text("다이어리 저장하기")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("Primary"), in: Capsule())
                .shadow(color: Color("Primary").opacity(0.22), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var readingTimelineSection: some View {
        let memos = viewModel.savedMemos(for: book.id)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("독서 타임라인")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(memos.isEmpty ? "책을 읽으며 남긴 조각들이 여기에 쌓여요." : "\(memos.count)개의 메모가 쌓였어요.")
                        .font(.caption)
                        .foregroundStyle(Color("TextSecondary"))
                }

                Spacer()

                Button {
                    isShowingMemoAddSheet = true
                } label: {
                    Label("메모", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Primary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("Primary").opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if memos.isEmpty {
                timelineEmptyCard
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(memos) { memo in
                        readingMemoCard(memo)
                    }
                }
            }
        }
    }

    private var timelineEmptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color("Primary").opacity(0.68))
                .frame(width: 66, height: 66)
                .background(Color("Primary").opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("아직 작성된 메모가 없어요.")
                .font(.subheadline.bold())
                .foregroundStyle(Color("TextPrimary"))

            Button {
                isShowingMemoAddSheet = true
            } label: {
                Text("첫 메모 남기기")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Primary"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color("Primary").opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color("Surface").opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color("Border").opacity(0.24), lineWidth: 1)
        }
    }

    private func readingMemoCard(_ memo: ReadingMemo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color("Primary"))
                    .frame(width: 10, height: 10)

                Rectangle()
                    .fill(Color("Primary").opacity(0.18))
                    .frame(width: 2, height: 44)
            }
            .frame(width: 14)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(memo.date)
                        .font(.caption.bold())
                        .foregroundStyle(Color("PrimaryDeep"))

                    if let page = memo.page {
                        Text("p.\(page)")
                            .font(.caption.bold())
                            .foregroundStyle(Color("TextSecondary"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AppBackground").opacity(0.72), in: Capsule())
                    }

                    Spacer()

                    Menu {
                        Button("수정") {
                            editingMemo = memo
                        }

                        Button("삭제", role: .destructive) {
                            Task { await viewModel.deleteReadingMemo(memo) }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color("TextMuted"))
                            .frame(width: 30, height: 30)
                            .background(Color("SurfaceElevated").opacity(0.86), in: Circle())
                    }
                }

                Text(memo.text)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary").opacity(0.86))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(Color("Surface").opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color("Border").opacity(0.2), lineWidth: 1)
            }
        }
    }

    private func diaryFieldTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.bold())
            .foregroundStyle(Color("TextSecondary"))
    }

    private func saveDiary() {
        isReviewFocused = false

        Task {
            _ = await viewModel.saveReview(
                bookId: book.id,
                rating: rating,
                content: reviewText,
                isPublic: isReviewPublic
            )
            _ = await viewModel.saveRatingAndReview(
                book: book,
                rating: rating,
                review: reviewText,
                readingStatus: readingStatus,
                startDate: BookMateDateFormatter.apiString(from: startDate),
                endDate: BookMateDateFormatter.apiString(from: endDate)
            )
        }
    }
}


#Preview {
    BookDetailView(viewModel: BookMateViewModel(), book: Book.dummyBooks[0])
}
