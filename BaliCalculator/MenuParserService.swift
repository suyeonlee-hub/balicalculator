//
//  MenuParserService.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import Foundation

final class MenuParserService {
    private let classifier = MenuClassifierService()

    // 1. 완성형 고유 명사 사전 (특정 시그니처 메뉴)
    private let exactMenuDict: [String: String] = [
        "tumis kangkung": "모닝글로리 볶음",
        "tumis kuciwis": "미니 양배추 볶음",
        "tumis toge": "숙주 볶음",
        "gado gado": "인도네시아식 샐러드",
        "sayur asem": "타마린드 야채탕",
        "es teh": "아이스티",
        "es jeruk": "오렌지 주스",
        "air mineral": "생수"
    ]

    // 2. 단어 조합형 사전 (인도네시아 요리 문법)
    private let baseIngredients: [String: String] = [
        "kwetiaw": "납작 쌀국수",
        "kwetiau": "납작 쌀국수",
        "bihun": "버미셀리",
        "mie": "국수",
        "nasi": "밥",
        "ayam": "닭고기",
        "sapi": "소고기",
        "kambing": "염소",
        "bebek": "오리고기",
        "babi": "돼지고기",
        "ikan": "생선",
        "seafood": "시푸드",
        "udang": "새우",
        "cumi": "오징어",
        "gurame": "구라미",
        "kangkung": "공심채",
        "tahu": "두부",
        "tempe": "템페"
    ]

    private let cookingMethods: [String: String] = [
        "goreng": "튀김/볶음",
        "tumis": "볶음",
        "bakar": "구이",
        "siram": "국물 끼얹은",
        "kuah": "탕",
        "rebus": "삶은",
        "crispy": "바삭 튀김",
        "asam manis": "탕수",
        "lada hitam": "블랙페퍼",
        "rica rica": "매콤 볶음",
        "balado": "칠리 양념"
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

        // 스마트 번역 엔진 호출
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

    // 스마트 조합 번역 엔진
    private func translateMenuName(_ rawName: String) -> String {
        let lower = rawName.lowercased()

        // 1) 고유 메뉴 사전 우선 탐색
        for (key, val) in exactMenuDict {
            if lower.contains(key) {
                return val
            }
        }

        // 2) 토큰 분해 후 조합 매핑
        var foundMethod: String? = nil
        var foundBase: [String] = []

        // 조리법 탐색
        for (methodKey, methodVal) in cookingMethods {
            if lower.contains(methodKey) {
                foundMethod = methodVal
                break
            }
        }

        // 재료 탐색
        for (ingKey, ingVal) in baseIngredients {
            if lower.contains(ingKey) {
                foundBase.append(ingVal)
            }
        }

        // 조합 규칙: [단백질/재료...] + [조리법]
        if !foundBase.isEmpty {
            let baseText = foundBase.joined(separator: " ")
            if let method = foundMethod {
                if method == "국물 끼얹은" {
                    return "\(method) \(baseText)" // 예: 국물 끼얹은 납작 쌀국수 닭고기
                } else {
                    return "\(baseText) \(method)" // 예: 버미셀리 소고기 볶음
                }
            }
            return baseText
        }

        return rawName // 매칭 실패 시 원문 노출
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
