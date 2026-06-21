//
//  SignupView.swift
//  BookMate
//
//  Created by 한채림 on 6/1/26.
//

import SwiftUI

private enum SignupFocusField {
    case email
    case password
    case passwordConfirm
    case nickname
}

private enum ValidationTone {
    case neutral
    case success
    case error
}

struct SignupView: View {
    @ObservedObject var authViewModel: AuthSessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var nickname = ""
    @State private var isSuggestingNickname = false
    @State private var isCheckingEmail = false
    @State private var isCheckingNickname = false
    @State private var emailAvailability: EmailAvailabilityResponse?
    @State private var nicknameAvailability: NicknameAvailabilityResponse?
    @FocusState private var focusedField: SignupFocusField?

    private var normalizedEmail: String {
        AuthValidation.normalizedEmail(email)
    }

    private var normalizedNickname: String {
        AuthValidation.normalizedNickname(nickname)
    }

    private var isEmailCheckedAndAvailable: Bool {
        emailAvailability?.available == true &&
        emailAvailability?.email == normalizedEmail
    }

    private var isNicknameCheckedAndAvailable: Bool {
        nicknameAvailability?.available == true &&
        nicknameAvailability?.nickname == normalizedNickname
    }

    private var canGoNext: Bool {
        AuthValidation.isValidEmail(email) &&
        isEmailCheckedAndAvailable &&
        AuthValidation.isValidPassword(password) &&
        password == passwordConfirm
    }

    private var canSubmit: Bool {
        AuthValidation.isValidNickname(nickname) &&
        isNicknameCheckedAndAvailable
    }

    private var displayedNickname: String {
        normalizedNickname.isEmpty ? "자동 생성 예정" : normalizedNickname
    }

    private var nicknameInitial: String {
        String(displayedNickname.prefix(1))
    }

    var body: some View {
        ZStack {
            Color("AppBackground")
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }

            VStack(spacing: 26) {
                header

                if step == 1 {
                    accountStep
                } else {
                    nicknameStep
                }

                Spacer()

                Button {
                    focusedField = nil

                    if step == 1 {
                        step = 2
                    } else {
                        Task {
                            await authViewModel.signup(
                                email: normalizedEmail,
                                password: password,
                                nickname: normalizedNickname
                            )
                        }
                    }
                } label: {
                    Text(step == 1 ? "다음" : "완료")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background((step == 1 ? canGoNext : canSubmit) ? Color("Primary") : Color.gray.opacity(0.25))
                        .foregroundStyle((step == 1 ? canGoNext : canSubmit) ? Color("PrimaryButtonText") : Color("TextSecondary"))
                        .clipShape(Capsule())
                        .shadow(color: Color("Primary").opacity(0.25), radius: 12, x: 0, y: 6)
                }
                .disabled(step == 1 ? !canGoNext : !canSubmit)
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)
            .padding(.bottom, 28)
        }
        .navigationBarBackButtonHidden(true)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: email) { _, newValue in
            let normalized = AuthValidation.normalizedEmail(newValue)
            if emailAvailability?.email != normalized {
                emailAvailability = nil
            }
        }
        .onChange(of: nickname) { _, newValue in
            let normalized = AuthValidation.normalizedNickname(newValue)
            if nicknameAvailability?.nickname != normalized {
                nicknameAvailability = nil
            }
        }
        .task(id: step) {
            guard step == 2,
                  normalizedNickname.isEmpty else {
                return
            }

            await suggestNickname()
        }
    }

    private var header: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left") {
                if step == 1 {
                    dismiss()
                } else {
                    step = 1
                }
            }

            Spacer()

            Text("회원가입")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepIndicator(current: 1)

            Text("계정 정보를\n입력해주세요")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("북메이트에서 사용할 이메일과 비밀번호를 설정합니다.")
                .foregroundStyle(Color("TextSecondary"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            emailField

            secureSignupField(
                title: "비밀번호",
                placeholder: "8자 이상 입력해주세요",
                text: $password,
                focus: .password,
                submitLabel: .next,
                helperText: AuthValidation.passwordHelperText(password),
                helperTone: password.isEmpty ? .neutral : (AuthValidation.isValidPassword(password) ? .success : .error)
            ) {
                focusedField = .passwordConfirm
            }

            secureSignupField(
                title: "비밀번호 확인",
                placeholder: "비밀번호를 다시 입력해주세요",
                text: $passwordConfirm,
                focus: .passwordConfirm,
                submitLabel: .done,
                helperText: AuthValidation.passwordConfirmHelperText(password: password, confirm: passwordConfirm),
                helperTone: passwordConfirm.isEmpty ? .neutral : (password == passwordConfirm ? .success : .error)
            ) {
                focusedField = nil
            }
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이메일 주소")
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundStyle(Color("TextSecondary").opacity(0.75))

                TextField(
                    "",
                    text: $email,
                    prompt: Text("example@bookmate.com")
                        .foregroundStyle(Color("TextSecondary").opacity(0.48))
                )
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .foregroundStyle(Color("TextPrimary"))
                    .tint(Color("Primary").opacity(0.68))
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }

                Button {
                    Task {
                        await checkEmailAvailability()
                    }
                } label: {
                    HStack(spacing: 5) {
                        if isCheckingEmail {
                            ProgressView()
                                .tint(Color("PrimaryDeep"))
                                .scaleEffect(0.72)
                        }

                        Text(isCheckingEmail ? "확인 중" : "중복확인")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color("PrimaryDeep"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Primary").opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!AuthValidation.isValidEmail(email) || isCheckingEmail)
                .opacity(AuthValidation.isValidEmail(email) ? 1 : 0.45)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            validationText(emailHelperText, tone: emailHelperTone)
        }
    }

    private var emailHelperText: String {
        if let emailAvailability,
           emailAvailability.email == normalizedEmail {
            return emailAvailability.message
        }

        return AuthValidation.emailHelperText(email)
    }

    private var emailHelperTone: ValidationTone {
        if email.isEmpty { return .neutral }
        if let emailAvailability,
           emailAvailability.email == normalizedEmail {
            return emailAvailability.available ? .success : .error
        }

        return AuthValidation.isValidEmail(email) ? .neutral : .error
    }

    private var nicknameStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepIndicator(current: 2)

            nicknamePreviewCard

            Text("사용하실 닉네임을\n설정해주세요")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color("TextPrimary"))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("닉네임은 최대 8자까지 사용할 수 있어요.")
                .foregroundStyle(Color("TextSecondary"))

            nicknameField

            Button {
                Task {
                    await suggestNickname()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSuggestingNickname {
                        ProgressView()
                            .tint(Color("Primary"))
                    } else {
                        Image(systemName: "sparkles")
                    }

                    Text(isSuggestingNickname ? "추천 닉네임 만드는 중..." : "다른 닉네임 추천받기")
                }
                .font(.caption.bold())
                .foregroundStyle(Color("Primary"))
            }
            .disabled(isSuggestingNickname)

            HStack(spacing: 12) {
                infoCard(icon: "textformat", title: "한글/영문/숫자")
                infoCard(icon: "ruler", title: "최대 8자")
            }
        }
    }

    private var nicknameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color("TextSecondary").opacity(0.75))

                TextField("최대 8자", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .nickname)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }

                Button {
                    Task {
                        await checkNicknameAvailability()
                    }
                } label: {
                    HStack(spacing: 5) {
                        if isCheckingNickname {
                            ProgressView()
                                .tint(Color("PrimaryDeep"))
                                .scaleEffect(0.72)
                        }

                        Text(isCheckingNickname ? "확인 중" : "중복확인")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color("PrimaryDeep"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color("Primary").opacity(0.18), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!AuthValidation.isValidNickname(nickname) || isCheckingNickname)
                .opacity(AuthValidation.isValidNickname(nickname) ? 1 : 0.45)
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            validationText(nicknameHelperText, tone: nicknameHelperTone)
        }
    }

    private var nicknameHelperText: String {
        if let nicknameAvailability,
           nicknameAvailability.nickname == normalizedNickname {
            return nicknameAvailability.message
        }

        return AuthValidation.nicknameHelperText(nickname)
    }

    private var nicknameHelperTone: ValidationTone {
        if nickname.isEmpty { return .neutral }
        if let nicknameAvailability,
           nicknameAvailability.nickname == normalizedNickname {
            return nicknameAvailability.available ? .success : .error
        }

        return AuthValidation.isValidNickname(nickname) ? .neutral : .error
    }

    private var nicknamePreviewCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color("Primary").opacity(0.12))
                    .frame(width: 92, height: 92)

                Text(nicknameInitial)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("PrimaryDeep"))
            }

            Text(displayedNickname)
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            Text(normalizedNickname.isEmpty ? "가입 시 서버가 자동으로 이름을 정해줘요." : "이 이름으로 북메이트를 시작해요.")
                .font(.caption)
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color("Surface").opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func stepIndicator(current: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Capsule()
                    .fill(current == 1 ? Color("Primary") : Color.gray.opacity(0.2))
                    .frame(width: 48, height: 6)

                Capsule()
                    .fill(current == 2 ? Color("Primary") : Color.gray.opacity(0.2))
                    .frame(width: 48, height: 6)
            }

            Spacer()

            Text("\(current) / 2")
                .fontWeight(.semibold)
                .foregroundStyle(Color("PrimaryDeep"))
        }
    }

    private func secureSignupField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        focus: SignupFocusField,
        submitLabel: SubmitLabel,
        helperText: String,
        helperTone: ValidationTone,
        onSubmit: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextSecondary"))

            HStack(spacing: 14) {
                Image(systemName: "lock")
                    .foregroundStyle(Color("TextSecondary").opacity(0.75))

                SecureField(placeholder, text: text)
                    .focused($focusedField, equals: focus)
                    .submitLabel(submitLabel)
                    .onSubmit {
                        onSubmit?()
                    }
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color("Surface").opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            validationText(helperText, tone: helperTone)
        }
    }

    private func validationText(_ text: String, tone: ValidationTone) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(validationColor(for: tone))
            .padding(.horizontal, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func validationColor(for tone: ValidationTone) -> Color {
        switch tone {
        case .neutral:
            return Color("TextSecondary").opacity(0.78)
        case .success:
            return Color("PrimaryDeep")
        case .error:
            return Color("Error")
        }
    }

    private func infoCard(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color("PrimaryDeep"))

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("TextPrimary"))
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(Color("Surface").opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func checkEmailAvailability() async {
        let emailToCheck = normalizedEmail
        guard AuthValidation.isValidEmail(emailToCheck),
              !isCheckingEmail else { return }

        focusedField = nil
        isCheckingEmail = true
        emailAvailability = await authViewModel.checkEmailAvailability(email: emailToCheck)
        isCheckingEmail = false
    }

    private func checkNicknameAvailability() async {
        let nicknameToCheck = normalizedNickname
        guard AuthValidation.isValidNickname(nicknameToCheck),
              !isCheckingNickname else { return }

        focusedField = nil
        isCheckingNickname = true
        nicknameAvailability = await authViewModel.checkNicknameAvailability(nickname: nicknameToCheck)
        isCheckingNickname = false
    }

    private func suggestNickname() async {
        guard !isSuggestingNickname else { return }

        isSuggestingNickname = true
        if let suggestedNickname = await authViewModel.suggestNickname() {
            nickname = suggestedNickname
            nicknameAvailability = NicknameAvailabilityResponse(
                nickname: suggestedNickname,
                available: true,
                message: "사용할 수 있는 닉네임이에요."
            )
        }
        isSuggestingNickname = false
    }
}

#Preview {
    SignupView(authViewModel: AuthSessionViewModel())
}
