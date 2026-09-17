//
//  MenuParserService.swift
//  BaliCalculator
//
//  Created by Su-Yeon Lee on 9/14/26.
//

import Foundation
import CoreGraphics


final class MenuParserService {
    // ⚠️ classifier 및 헬퍼 메서드들을 같은 파일 내에서 접근 가능하도록 fileprivate/internal로 통일
    let classifier = MenuClassifierService()

    // 1. 완성형 고유명사 및 시그니처 메뉴
    private let exactMenuDict: [String: String] = [
        "babi guling": "발리식 돼지 통구이(바비 굴링)",
        "ayam betutu": "발리식 전통 훈제 향신료 치킨(베투투)",
        "bebek betutu": "발리식 전통 훈제 오리(베투투)",
        "bebek bengil": "크리스피 덕(바삭한 오리 튀김)",
        "gado gado": "인도네시아식 땅콩소스 샐러드",
        "sayur asem": "타마린드 채소 맑은 탕",
        "sayur lodeh": "코코넛 밀크 채소 카레탕",
        "soto ayam lamongan": "라몽안식 닭고기 국밥(소토 아얌)",
        "soto betawi": "자카르타식 코코넛 밀크 소고기탕",
        "empal gentong": "찌레본식 소고기 도가니탕",
        "rawon": "검은 육수의 동자바식 소고기탕(라원)",
        "tempe mendoan": "반죽을 얇게 입혀 촉촉하게 튀긴 템페",
        "es campur": "인도네시아식 과일 믹스 빙수",
        "es teler": "아보카도 코코넛 빙수",
        "es cendol": "판단 젤리 코코넛 빙수(첸돌)",
        "teh botol sosro": "소스로 자스민 병 홍차",
        "teh botol": "병 홍차",
        "air mineral": "생수"
    ]

    // 2. Layer 1: 상태, 소스, 양념, 맛, 형용사
    private let modifierDict: [String: String] = [
        "sambal matah": "발리식 생삼발 양념",
        "sambal mbe": "튀긴 마늘 샬롯 삼발 양념",
        "sambal hijau": "초록 고추 삼발 양념",
        "sambal ijo": "초록 고추 삼발 양념",
        "sambal terasi": "새우젓 삼발 양념",
        "sambal bawang": "알싸한 마늘 삼발 양념",
        "saus padang": "파당식 매콤달콤 칠리소스",
        "saus tiram": "감칠맛 굴소스",
        "asam manis": "새콤달콤 탕수 소스",
        "lada hitam": "블랙페퍼 소스",
        "telur asin": "짭조름한 소금 절임 노른자 소스",
        "bakar madu": "달콤한 꿀 발라 구운",
        "mentega": "버터 풍미",
        "keju": "치즈",
        "mayonnaise": "마요네즈",
        "mayones": "마요네즈",
        "rica rica": "마나도식 매콤 볶음 양념",
        "balado": "칠리 고추 볶음 양념",
        "bumbu bali": "발리식 매콤 복합 향신 양념",
        "kacang": "땅콩 소스",
        "asin": "염장(짭조름한)",
        "manis": "달콤한",
        "pedas": "매운",
        "crispy": "바삭한",
        "krispi": "바삭한",
        "komplit": "모둠 종합 세트",
        "spesial": "스페셜",
        "special": "스페셜",
        "jawa": "자바식",
        "kampung": "시골 풍미"
    ]

    // 3. Layer 2: 단백질 및 식재료
    private let proteinDict: [String: String] = [
        "ayam": "닭고기",
        "sapi": "소고기",
        "iga": "소갈비",
        "iga sapi": "소갈비",
        "buntut": "소꼬리",
        "babi": "돼지고기",
        "samcan": "돼지 삼겹살",
        "bebek": "오리고기",
        "kambing": "양/염소고기",
        "bakso": "미트볼(완자)",
        "sosis": "소시지",
        "ikan": "생선",
        "udang": "새우",
        "cumi": "오징어",
        "kepiting": "게",
        "kerang": "조개",
        "gurame": "구라메 민물고기",
        "kakap": "도미/농어",
        "bawal": "병어",
        "seafood": "모둠 해산물",
        "telur": "계란",
        "tahu": "두부",
        "tempe": "템페",
        "kangkung": "모닝글로리(공심채)",
        "toge": "숙주",
        "tauge": "숙주",
        "kuciwis": "미니 양배추",
        "buncis": "그린빈(줄기콩)",
        "jamur": "버섯",
        "terong": "가지",
        "pare": "여주"
    ]

    // 4. Layer 3: 조리 방식
    private let methodDict: [String: String] = [
        "goreng tepung": "튀김옷을 입혀 바삭하게 튀긴",
        "goreng": "볶음/튀김",
        "bakar": "숯불 구이",
        "panggang": "오븐/그릴 구이",
        "rebus": "삶은",
        "kuah": "국물",
        "siram": "진한 소스를 끼얹은",
        "geprek": "바삭하게 튀겨 으깬",
        "penyet": "양념과 함께 으깬",
        "suwir": "잘게 찢은",
        "tumis": "팬에 볶아낸",
        "oseng": "센 불에 볶은",
        "pepes": "바나나잎에 싸서 찐",
        "lilit": "레몬글라스에 돌돌 만"
    ]

    // 5. Layer 4: 기본 주식, 면, 국물 베이스, 음료
    private let stapleDict: [String: String] = [
        "nasi": "밥",
        "mie": "국수",
        "kwetiaw": "납작 쌀국수",
        "kwetiau": "납작 쌀국수",
        "bihun": "버미셀리(가는 쌀국수)",
        "lontong": "바나나잎 쌀떡",
        "bubur": "죽",
        "capcay": "모둠 채소 볶음",
        "sup": "수프/탕",
        "sop": "수프/탕",
        "soto": "인도네시아 전통 탕",
        "gulai": "코코넛 커리 스튜",
        "rendang": "장시간 조린 고기 스튜(른당)",
        "sate": "사테(꼬치구이)",
        "es teh": "아이스티",
        "es jeruk": "생 오렌지 쥬스",
        "jus alpukat": "아보카도 주스",
        "jus mangga": "망고 주스",
        "jus semangka": "수박 주스",
        "jus": "생과일 주스",
        "kopi": "커피",
        "teh": "차(Tea)",
        "beer": "맥주",
        "pisang goreng": "바나나 튀김",
        "roti bakar": "토스트 구이"
    ]

    // MARK: - 기존 단일 줄 파싱 (하위 호환 유지)
    func parseMenuItems(from rawLines: [String]) -> [MenuItem] {
        var parsedItems: [MenuItem] = []
        for line in rawLines {
            if let item = parseLine(line) {
                parsedItems.append(item)
            }
        }
        return parsedItems
    }

    // MARK: - 2D 공간 기반 페어링 파싱 (새 메인 엔진)
    func parseElements(_ elements: [OCRTextElement]) -> [MenuItem] {
        // Vision 좌표계는 좌하단이 (0,0)이므로 Y축 내림차순(위에서 아래로) 정렬
        let sorted = elements.sorted { $0.box.midY > $1.box.midY }

        var nameCandidates: [OCRTextElement] = []
        var priceCandidates: [(value: Double, element: OCRTextElement)] = []

        for item in sorted {
            if let price = extractStandalonePrice(from: item.text) {
                priceCandidates.append((price, item))
            } else {
                nameCandidates.append(item)
            }
        }

        var matchedItems: [MenuItem] = []
        var usedPriceIndices = Set<Int>()

        for nameItem in nameCandidates {
            // 1) 인라인 검사: 텍스트 자체에 이미 가격이 함께 있는 경우
            if let parsed = parseLine(nameItem.text) {
                matchedItems.append(parsed)
                continue
            }

            // 2) 수평 공간 매칭 (같은 행, Y 오차 0.02 이내)
            var bestPriceIndex: Int? = nil
            var minDistance: CGFloat = .infinity

            for (idx, p) in priceCandidates.enumerated() where !usedPriceIndices.contains(idx) {
                let yDiff = abs(nameItem.box.midY - p.element.box.midY)
                let isSameRow = yDiff < 0.02
                let isRightSide = p.element.box.minX >= (nameItem.box.minX - 0.05)

                if isSameRow && isRightSide {
                    let distance = p.element.box.minX - nameItem.box.maxX
                    if distance < minDistance {
                        minDistance = distance
                        bestPriceIndex = idx
                    }
                }
            }

            // 3) 수직 공간 매칭 (메뉴명 바로 아래 줄에 가격이 있는 경우)
            if bestPriceIndex == nil {
                for (idx, p) in priceCandidates.enumerated() where !usedPriceIndices.contains(idx) {
                    let isBelow = (nameItem.box.minY - p.element.box.maxY) > 0 && (nameItem.box.minY - p.element.box.maxY) < 0.05
                    let xOverlap = abs(nameItem.box.minX - p.element.box.minX) < 0.15

                    if isBelow && xOverlap {
                        bestPriceIndex = idx
                        break
                    }
                }
            }

            // 매칭 성공 시 MenuItem 생성
            if let pIdx = bestPriceIndex {
                usedPriceIndices.insert(pIdx)
                let priceVal = priceCandidates[pIdx].value
                let rawName = nameItem.text.trimmingCharacters(in: CharacterSet(charactersIn: "-:·•,"))

                let translated = translateMenuName(rawName)
                let category = classifier.predictCategory(for: rawName)

                matchedItems.append(MenuItem(
                    rawName: rawName,
                    translatedName: translated,
                    category: category,
                    localPrice: priceVal,
                    count: 0
                ))
            }
        }

        return matchedItems
    }

    // MARK: - 내부 헬퍼 메서드
    func parseLine(_ line: String) -> MenuItem? {
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

    func translateMenuName(_ rawName: String) -> String {
        let lower = rawName.lowercased()

        // 1) 고유명사 사전 우선 탐색
        for (key, val) in exactMenuDict {
            if lower.contains(key) {
                return val
            }
        }

        // 2) 다중 단어 구문(복합어) 우선 치환
        var workingText = lower
        var replacedPhrases: [String: (korean: String, layer: Int)] = [:]

        let allMultiWordDicts: [(dict: [String: String], layer: Int)] = [
            (modifierDict, 1),
            (proteinDict, 2),
            (methodDict, 3),
            (stapleDict, 4)
        ]

        for (dict, layer) in allMultiWordDicts {
            for (key, val) in dict where key.contains(" ") {
                if workingText.contains(key) {
                    let placeholder = "__PHRASE_\(replacedPhrases.count)__"
                    replacedPhrases[placeholder] = (val, layer)
                    workingText = workingText.replacingOccurrences(of: key, with: placeholder)
                }
            }
        }

        // 3) 토큰 분해 및 레이어 할당
        let tokens = workingText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var recognizedModifiers: [String] = []
        var recognizedProteins: [String] = []
        var recognizedMethods: [String] = []
        var recognizedStaples: [String] = []
        var unmappedWords: [String] = []

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
                unmappedWords.append(token)
            }
        }

        // 4) 한국어 어순 조립
        var finalComponents: [String] = []
        if !unmappedWords.isEmpty { finalComponents.append(unmappedWords.joined(separator: " ")) }
        if !recognizedModifiers.isEmpty { finalComponents.append(recognizedModifiers.joined(separator: " ")) }
        if !recognizedProteins.isEmpty { finalComponents.append(recognizedProteins.joined(separator: " ")) }
        if !recognizedMethods.isEmpty { finalComponents.append(recognizedMethods.joined(separator: " ")) }
        if !recognizedStaples.isEmpty { finalComponents.append(recognizedStaples.joined(separator: " ")) }

        if finalComponents.joined(separator: " ") == rawName.lowercased() {
            return rawName
        }

        return finalComponents.joined(separator: " ")
    }

    private func extractStandalonePrice(from string: String) -> Double? {
        let pattern = #"^(?i)(?:rp\.?\s*)?(\d{1,3}(?:\.\d{3})+|\d+(?:[.,]\d+)?)\s*(k)?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(location: 0, length: (string as NSString).length)
        if regex.firstMatch(in: string, range: range) != nil {
            return extractPriceValue(from: string)
        }
        return nil
    }

    func extractPriceValue(from string: String) -> Double? {
        var clean = string.lowercased().replacingOccurrences(of: "rp", with: "").trimmingCharacters(in: .whitespaces)
        let isThousandUnit = clean.contains("k")
        clean = clean.replacingOccurrences(of: "k", with: "").trimmingCharacters(in: .whitespaces)
        clean = clean.replacingOccurrences(of: ".", with: "")
        clean = clean.replacingOccurrences(of: ",", with: ".")

        guard let number = Double(clean) else { return nil }
        return isThousandUnit ? (number * 1000.0) : number
    }
}
