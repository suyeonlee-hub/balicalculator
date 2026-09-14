//
//  VisionOCRService.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import UIKit
import Vision

final class VisionOCRService {
    
    // 이미지를 비동기로 받아 텍스트 라인 배열을 반환하는 메서드
    func recognizeText(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        // 1. Vision 텍스트 인식 요청 생성
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                print("Vision OCR 오류: \(error?.localizedDescription ?? "알 수 없음")")
                DispatchQueue.main.async { completion([]) }
                return
            }

            // 2. 인식된 각 영역에서 가장 신뢰도 높은 텍스트만 추출
            var extractedLines: [String] = []
            for observation in observations {
                if let candidate = observation.topCandidates(1).first {
                    let trimmed = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        extractedLines.append(trimmed)
                    }
                }
            }

            // 3. 메인 스레드로 결과 콜백 전달
            DispatchQueue.main.async {
                completion(extractedLines)
            }
        }

        // 3. 정확도 및 언어 설정 (정밀 모드 + 영어/인니어 라틴 문자셋 최적화)
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // 4. 백그라운드 큐에서 실행하여 UI 멈춤 방지
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Vision 실행 실패: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }
}
