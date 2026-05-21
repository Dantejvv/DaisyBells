import Testing
import SwiftUI
@testable import DaisyBells

/// Tests for NumericKeypad's state predicates (canSign, canDecimal, canBackspace).
/// These are pure functions of `fieldKind` + `draft` and are the only part of
/// NumericKeypad that has business logic worth unit-testing.
@Suite(.serialized)
struct NumericKeypadStateTests {

    private func makeKeypad(
        kind: NumericKeypad.FieldKind,
        draft: String,
        canSameAsLast: Bool = false,
        canNext: Bool = false
    ) -> NumericKeypad {
        NumericKeypad(
            fieldKind: kind,
            canSameAsLast: canSameAsLast,
            canNext: canNext,
            draft: .constant(draft),
            onSameAsLast: {},
            onNext: {},
            onDone: {}
        )
    }

    // MARK: - canSign

    @Test @MainActor
    func canSignFalseForDecimal() {
        let pad = makeKeypad(kind: .decimal, draft: "10")
        #expect(pad.canSign == false)
    }

    @Test @MainActor
    func canSignFalseForInteger() {
        let pad = makeKeypad(kind: .integer, draft: "10")
        #expect(pad.canSign == false)
    }

    @Test @MainActor
    func canSignFalseForSignedDecimalWhenDraftEmpty() {
        let pad = makeKeypad(kind: .signedDecimal, draft: "")
        #expect(pad.canSign == false)
    }

    @Test @MainActor
    func canSignTrueForSignedDecimalWithDraft() {
        let pad = makeKeypad(kind: .signedDecimal, draft: "10")
        #expect(pad.canSign == true)
    }

    @Test @MainActor
    func canSignTrueForSignedDecimalWithExistingNegative() {
        // A negative draft should still allow toggling back to positive.
        let pad = makeKeypad(kind: .signedDecimal, draft: "-10")
        #expect(pad.canSign == true)
    }

    // MARK: - canDecimal

    @Test @MainActor
    func canDecimalFalseForInteger() {
        let pad = makeKeypad(kind: .integer, draft: "")
        #expect(pad.canDecimal == false)
    }

    @Test @MainActor
    func canDecimalTrueForDecimalWithoutExistingDot() {
        let pad = makeKeypad(kind: .decimal, draft: "10")
        #expect(pad.canDecimal == true)
    }

    @Test @MainActor
    func canDecimalFalseForDecimalWithExistingDot() {
        let pad = makeKeypad(kind: .decimal, draft: "10.5")
        #expect(pad.canDecimal == false)
    }

    @Test @MainActor
    func canDecimalTrueForEmptyDraft() {
        // User can start with ".5" — first character is the dot.
        let pad = makeKeypad(kind: .decimal, draft: "")
        #expect(pad.canDecimal == true)
    }

    @Test @MainActor
    func canDecimalTrueForSignedDecimalWithoutDot() {
        let pad = makeKeypad(kind: .signedDecimal, draft: "-5")
        #expect(pad.canDecimal == true)
    }

    @Test @MainActor
    func canDecimalFalseForSignedDecimalWithDot() {
        let pad = makeKeypad(kind: .signedDecimal, draft: "-5.0")
        #expect(pad.canDecimal == false)
    }

    // MARK: - canBackspace

    @Test @MainActor
    func canBackspaceFalseForEmptyDraft() {
        let pad = makeKeypad(kind: .decimal, draft: "")
        #expect(pad.canBackspace == false)
    }

    @Test @MainActor
    func canBackspaceTrueForAnyNonEmpty() {
        for draft in ["1", "10", "10.5", "-10", "0"] {
            let pad = makeKeypad(kind: .signedDecimal, draft: draft)
            #expect(pad.canBackspace == true, "expected canBackspace=true for draft '\(draft)'")
        }
    }

    // MARK: - FieldKind invariants

    @Test
    func decimalAllowsDecimalDisallowsSign() {
        #expect(NumericKeypad.FieldKind.decimal.allowsDecimal == true)
        #expect(NumericKeypad.FieldKind.decimal.allowsSign == false)
    }

    @Test
    func integerDisallowsBoth() {
        #expect(NumericKeypad.FieldKind.integer.allowsDecimal == false)
        #expect(NumericKeypad.FieldKind.integer.allowsSign == false)
    }

    @Test
    func signedDecimalAllowsBoth() {
        #expect(NumericKeypad.FieldKind.signedDecimal.allowsDecimal == true)
        #expect(NumericKeypad.FieldKind.signedDecimal.allowsSign == true)
    }
}
