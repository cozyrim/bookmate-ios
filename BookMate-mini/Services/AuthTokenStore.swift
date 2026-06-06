//
//  AuthTokenStore.swift
//  BookMate-mini
//
//  Created by 한채림 on 6/1/26.
//

import Foundation

protocol AuthTokenStore {
    func save(_ token: String)
    func load() -> String?
    func clear()
}

final class KeychainTokenStore: AuthTokenStore {
    private let service = "BookMateMini"
    private let account = "accessToken"
    
    
    // 로그인 성공 후 토큰 저장
    func save(_ token: String) {
        clear()
        
        let tokenData = Data(token.utf8)
        
        // 토큰을 keychain에 저장할 때 필요한 설명서
        // key는 String, value는 어떤 타입이든 가능
        // 저장할 물건의 정보표
//        종류: 일반 비밀번호 타입
//        서비스 이름: BookMateMini
//        계정 이름: accessToken
//        저장할 값: tokenData
//        접근 조건: 기기가 잠금 해제되어 있을 때만
        // kSec...는 Apple의 Security framework에서 제공하는 Keychain 전용 상수
            // Security 관련 상수
        // Keychain에게 넘기는 정해진 키 이름
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword, // 저장할 데이터 종류 - 일반 비밀번호 형태
            kSecAttrService as String: service, // 어떤 서비스 이름으로 저장? - "BookMateMini" 앱에서 쓰는 토큰 저장소
            kSecAttrAccount as String: account, // 어떤 항목인지 구분하는 이름 - BookMateMini 서비스 안의 accessToken 항목
            kSecValueData as String: tokenData, // 실제로 저장할 값 - Keychain은 문자열을 바로 저장하기보다 Data 형태로 저장해서 "abc.def.ghi" 같은 토큰 문자열을 Data로 바꿔서 넣음
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // 언제 접근가능하게 할지 정하는 보안 옵션 - 기기가 잠금 해제되어 있을 때만 접근 가능
//            이 기기에서만 사용 가능
//            iCloud 백업으로 다른 기기에 복원되지 않음
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        // Keychain API는 오래된 Security framework 함수라서 Swift 딕셔너리를 직접 받는 게 아니라 CFDictionary를 원해.
        
        
        
        if status != errSecSuccess {
            DebugLogger.log("Keychain 토큰 저장 실패:", status)
        }
    }
    
    // 앱이 다시 켜졌을 때 토큰 꺼내기
    func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true, // 찾기만 하지 말고 실제 저장된 Data를 돌려줘
            kSecMatchLimit as String: kSecMatchLimitOne // 조건에 맞는 것 하나만 가져와
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        guard let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }

    // 로그아웃할 때 토큰 삭제
    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
