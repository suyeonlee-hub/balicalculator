//
//  MenuParserService.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import Foundation

final class MenuParserService {
    private let classifier = MenuClassifierService()

    // 1. 고유명사/시그니처 메뉴 완제 사전
    private let exactMenuDict: [String: String] = [
        "tumis kangkung": "공심채 볶음",
        "tumis kuciwis": "미니 양배추 볶음",
        "tumis toge": "숙주 볶음",
        "gado gado": "가도가도 샐러드",
        "sayur asem": "새콤 채소탕",
        "es teh": "아이스티",
        "es jeruk": "오렌지 주스",
        "air mineral": "생수"
    ]

    // 2. 단어 레이어별 사전 (한국어 조합 순서에 맞춰 분리)
    // Layer 1: 상태, 소스, 형용사 (가장 앞에 위치)
    private let modifierDict: [String: String] = [
        "asin": "염장(짠)",
        "manis": "달콤",
        "pedas": "매운",
        "tawar": "무설탕",
        "asam manis": "새콤달콤",
        "lada hitam": "블랙페퍼",
        "keju": "치즈",
        "crispy": "바삭한"
    ]

    // Layer 2: 단백질 및 토핑 재료
    private let proteinDict: [String: String] = [
        "ayam": "닭고기",
        "sapi": "소고기",
        "bebek": "오리고기",
        "babi": "돼지고기",
        "kambing": "염소고기",
        "ikan": "생선",
        "udang": "새우",
        "cumi": "오징어",
        "seafood": "해산물",
        "bakso": "미트볼",
        "telur": "계란",
        "tahu": "두부",
        "tempe": "템페",
        "kangkung": "모닝글로리"
    ]

    // Layer 3: 조리 방식
    private let methodDict: [String: String] = [
        "goreng": "볶음",
        "bakar": "구이",
        "rebus": "삶은",
        "kuah": "국물",
        "siram": "소스얹은",
        "panggang": "오븐구이"
    ]

    // Layer 4: 기본 주식/면류 (한국어 문장의 가장 끝에 위치)
    private let stapleDict: [String: String] = [
        "nasi": "밥",
        "mie": "국수",
        "kwetiaw": "쌀국수",
        "kwetiau": "쌀국수",
        "bihun": "버미셀리",
        "sup": "수프",
        "soto": "탕"
    ]

    func parseMenuItems(from rawLines: [String]) -> [MenuItem] {
        var parsedItems: [MenuItem] = []
        for line in rawLines {
            if let item = parseLine(line) {
                parsedItems.append(item)
            }
        }
        return parsedItems
    }

    private func parseLine(_ line: String) -> MenuItem? {
        let pricePattern = #"(?i)(?:rp\.?\s*)?(\d{1,3}(?:\.\d{3})+|\d+(?:[.,]\d+)?)\s*(k)?"#
        guard let regex = try? NSRegularExpression(pattern: pricePattern) else { return nil }

        let nsString = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsString.length))

        guard let match = matches.last else { return nil }

        let priceString = nsString.substring(with: match.range)
        let nameString = nsString.replacingCharacters(in: match.range, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-:·•,"))

        guard !nameString.isEmpty, let priceValue = extractPriceValue(from: priceString) else {
            return nil
        }

        let translated = translateMenuName(nameString)
        let category = classifier.predictCategory(for: nameString)

        return MenuItem(
            rawName: nameString,
            translatedName: translated,
            category: category,
            localPrice: priceValue,
            count: 0
        )
    }

    // 토큰 기반 어순 재배열 번역 엔진
        private func translateMenuName(_ rawName: String) -> String {
            let lower = rawName.lowercased()

            // 1) 완성형 고유명사 사전 우선 탐색
            for (key, val) in exactMenuDict {
                if lower.contains(key) {
                    return val
                }
            }

            // 2) 다중 단어 키(예: "telur asin", "asam manis", "lada hitam") 우선 매핑
            var workingText = lower
            var replacedPhrases: [String: (korean: String, layer: Int)] = [:]
            
            let allMultiWordDicts: [(dict: [String: String], layer: Int)] = [
                (modifierDict, 1),
                (proteinDict, 2),
                (methodDict, 3),
                (stapleDict, 4)
            ]

            // 복합어 먼저 치환 (공백 포함 키워드 보호)
            for (dict, layer) in allMultiWordDicts {
                for (key, val) in dict where key.contains(" ") {
                    if workingText.contains(key) {
                        let placeholder = "__PHRASE_\(replacedPhrases.count)__"
                        replacedPhrases[placeholder] = (val, layer)
                        workingText = workingText.replacingOccurrences(of: key, with: placeholder)
                    }
                }
            }

            // 3) 단어 단위 분해 및 레이어 할당
            let tokens = workingText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            var recognizedModifiers: [String] = []  // Layer 1
            var recognizedProteins: [String] = []   // Layer 2
            var recognizedMethods: [String] = []    // Layer 3
            var recognizedStaples: [String] = []    // Layer 4
            var unmappedWords: [String] = []        // 사전에 없는 원어 단어

            for token in tokens {
                if let matched = replacedPhrases[token] {
                    switch matched.layer {
                    case 1: recognizedModifiers.append(matched.korean)
                    case 2: recognizedProteins.append(matched.korean)
                    case 3: recognizedMethods.append(matched.korean)
                    case 4: recognizedStaples.append(matched.korean)
                    default: break
                    }
                } else if let val = modifierDict[token] {
                    recognizedModifiers.append(val)
                } else if let val = proteinDict[token] {
                    recognizedProteins.append(val)
                } else if let val = methodDict[token] {
                    recognizedMethods.append(val)
                } else if let val = stapleDict[token] {
                    recognizedStaples.append(val)
                } else {
                    // 사전에 없는 단어는 원어 그대로 보존
                    unmappedWords.append(token)
                }
            }

            // 4) 한국어 어순 조립: [미번역 원어 단어] + [상태/양념] + [재료] + [조리법] + [주식]
            var finalComponents: [String] = []
            if !unmappedWords.isEmpty { finalComponents.append(unmappedWords.joined(separator: " ")) }
            if !recognizedModifiers.isEmpty { finalComponents.append(recognizedModifiers.joined(separator: " ")) }
            if !recognizedProteins.isEmpty { finalComponents.append(recognizedProteins.joined(separator: " ")) }
            if !recognizedMethods.isEmpty { finalComponents.append(recognizedMethods.joined(separator: " ")) }
            if !recognizedStaples.isEmpty { finalComponents.append(recognizedStaples.joined(separator: " ")) }

            // 전체가 미번역 단어뿐인 경우 원문 반환
            if finalComponents.joined(separator: " ") == rawName.lowercased() {
                return rawName
            }

            return finalComponents.joined(separator: " ")
        }

    private func extractPriceValue(from string: String) -> Double? {
        var clean = string.lowercased().replacingOccurrences(of: "rp", with: "").trimmingCharacters(in: .whitespaces)
        let isThousandUnit = clean.contains("k")
        clean = clean.replacingOccurrences(of: "k", with: "").trimmingCharacters(in: .whitespaces)
        clean = clean.replacingOccurrences(of: ".", with: "")
        clean = clean.replacingOccurrences(of: ",", with: ".")

        guard let number = Double(clean) else { return nil }
        return isThousandUnit ? (number * 1000.0) : number
    }
}
