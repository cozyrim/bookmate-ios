# Guestbook Send Performance

## Goal

방명록 전송 버튼을 누른 뒤 사용자가 기다리는 시간을 줄인다.

측정 기준은 평균 응답 시간만 보지 않고 다음 지표를 함께 본다.

- `PostGuestbookOptimisticUI`: 전송 요청 직후 임시 방명록을 화면에 삽입하는 시간
- `PostGuestbookAPI`: 방명록 작성 API round trip 시간
- `PostGuestbookTotal`: 전송 시작부터 서버 응답으로 임시 메시지를 교체할 때까지의 전체 시간

## iOS Change

전송 버튼을 누르면 입력창을 먼저 비우고, 임시 방명록을 리스트 상단에 바로 삽입한다.

서버 응답이 성공하면 임시 메시지를 실제 서버 메시지로 교체한다. 실패하면 임시 메시지를 제거하고 입력 내용을 다시 복구한다.

```swift
let optimisticMessage = makeOptimisticMessage(content: trimmedContent)
pendingMessageIDs.insert(optimisticMessage.id)
messages.insert(optimisticMessage, at: 0)

let newMessage = try await socialService.writeGuestbook(...)
replaceOptimisticMessage(id: optimisticMessage.id, with: newMessage)
```

측정은 `os_signpost`로 구간을 나누어 기록한다.

```swift
PerformanceLogger.begin("PostGuestbookOptimisticUI", id: optimisticSignpostID)
messages.insert(optimisticMessage, at: 0)
PerformanceLogger.end("PostGuestbookOptimisticUI", id: optimisticSignpostID)
```

## Server Change

방명록 저장 응답 경로에서 FCM 발송을 분리한다.

기존 흐름은 방명록 저장 후 FCM 발송까지 같은 요청 안에서 처리했다.

```java
GuestbookEntity savedMessage = guestbookRepository.save(message);
pushNotificationService.sendGuestbookMessageNotification(targetUser, writer, savedMessage);
return GuestbookMessageResponse.from(savedMessage);
```

개선 후에는 방명록 저장 트랜잭션이 커밋된 뒤 비동기 작업으로 푸시 발송을 넘긴다.

```java
GuestbookEntity savedMessage = guestbookRepository.save(message);
sendGuestbookNotificationAfterCommit(targetUser, writer, savedMessage);
return GuestbookMessageResponse.from(savedMessage);
```

```java
@Async
@Transactional
public void sendGuestbookMessageNotificationAsync(...) {
    sendToUser(targetUserId, payload);
}
```

## Measuring Again

Instruments에서 `os_signpost` Instrument를 열고 다음 이름을 필터링한다.

- `PostGuestbookOptimisticUI`
- `PostGuestbookAPI`
- `PostGuestbookTotal`

권장 측정 방식:

- 실기기에서 측정
- 같은 네트워크에서 20회 이상 반복
- 첫 1-2회는 워밍업으로 제외
- `p50`, `p95`, `max`, `avg`를 기록

포트폴리오에는 `PostGuestbookOptimisticUI`를 사용자 체감 개선 지표로, `PostGuestbookAPI`와 `PostGuestbookTotal`을 원인 분석 지표로 사용한다.
