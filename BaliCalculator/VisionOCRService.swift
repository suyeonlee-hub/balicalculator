//
//  VisionOCRService.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import Vision
import UIKit

struct OCRTextElement {
    let text: String
    let box: CGRect // Vision 정규화 좌표계 (0.0 ~ 1.0, 좌하단이 0,0)
}

final class VisionOCRService {
    func processImage(_ image: UIImage, completion: @escaping ([OCRTextElement]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        // 1. 카메라/갤러리 사진의 회전 메타데이터 추출
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            var elements: [OCRTextElement] = []
            for obs in observations {
                if let topCandidate = obs.topCandidates(1).first {
                    let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty {
                        elements.append(OCRTextElement(text: text, box: obs.boundingBox))
                    }
                }
            }
            
            // 2. 메인 스레드로 안전하게 콜백 반환
            DispatchQueue.main.async {
                completion(elements)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // 인니어 고유명사 보호
        request.recognitionLanguages = ["id-ID", "en-US"]

        // 3. 방향 정보(orientation)를 포함하여 핸들러 생성
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

// MARK: - UIImage.Orientation -> CGImagePropertyOrientation 변환 확장
private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
