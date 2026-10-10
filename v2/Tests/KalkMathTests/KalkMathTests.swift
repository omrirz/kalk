import XCTest
@testable import KalkMath

final class KalkMathTests: XCTestCase {
    private var engine: MathEngine!

    override func setUpWithError() throws {
        engine = try MathEngine()
    }

    private func result(_ input: String) throws -> String {
        try engine.evaluate(input).formattedValue
    }

    func testNumbers() throws {
        XCTAssertEqual(try result("1 + 2 * 3"), "7")
        XCTAssertEqual(try result("2 ^ 3 ^ 2"), "512")
        XCTAssertEqual(try result("0.1 + 0.2"), "0.3")
        XCTAssertEqual(try result("2pi"), "6.2831853071796")
        XCTAssertEqual(try result("5!"), "120")
        XCTAssertEqual(try result("sin(30 deg)"), "0.5")
    }

    func testVectorsAndMatrices() throws {
        XCTAssertEqual(try result("[1, 2, 3] * 2"), "[2, 4, 6]")
        XCTAssertEqual(try result("[1, 2, 3] + [4, 5, 6]"), "[5, 7, 9]")
        XCTAssertEqual(try result("dot([1, 2, 3], [4, 5, 6])"), "32")
        XCTAssertEqual(try result("cross([1, 0, 0], [0, 1, 0])"), "[0, 0, 1]")
        XCTAssertEqual(try result("det([1, 2; 3, 4])"), "-2")
        XCTAssertEqual(try result("[1, 2; 3, 4] * [5; 6]"), "[[17], [39]]")
    }

    func testUnitsAndComplexNumbers() throws {
        XCTAssertEqual(try result("5 cm to inch"), "1.9685039370079 inch")
        XCTAssertEqual(try result("sqrt(-4)"), "2i")
    }

    func testStatementsAndFunctions() throws {
        XCTAssertEqual(try result("a = 3; b = 4; sqrt(a^2 + b^2)"), "5")
        XCTAssertEqual(try result("f(x) = x^2; f(3) + f(4)"), "25")
        XCTAssertEqual(try engine.evaluate("f(x) = x^2").kind, .functionDefinition)
        XCTAssertEqual(try engine.evaluate("").kind, .empty)
        XCTAssertEqual(try engine.evaluate("x = 1;").kind, .empty)
    }

    func testTex() throws {
        XCTAssertEqual(try engine.evaluate("sqrt(2)/3").tex, "\\frac{\\sqrt{2}}{3}")
        XCTAssertEqual(try engine.evaluate("").tex, "")
        XCTAssertTrue(try engine.evaluate("[1, 2, 3]").tex.contains("bmatrix"))
    }

    func testErrors() {
        XCTAssertThrowsError(try engine.evaluate("2 +")) { error in
            XCTAssertTrue((error as? MathError)?.message.contains("Unexpected end of expression") == true)
        }
        XCTAssertThrowsError(try engine.evaluate("foo + 1")) { error in
            XCTAssertTrue((error as? MathError)?.message.contains("Undefined symbol foo") == true)
        }
    }
}
