import SwiftUI
import UIKit

// MARK: - Single-line bridge (UITextField)

struct BridgedSingleLineTextInput: UIViewRepresentable {
    typealias UIViewType = UITextField

    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let placeholderColor: UIColor
    let autocapitalization: UITextAutocapitalizationType
    let autocorrection: UITextAutocorrectionType
    let returnKey: UIReturnKeyType
    let onSubmit: (() -> Void)?

    func makeCoordinator() -> SingleLineCoordinator {
        SingleLineCoordinator(text: $text, isFocused: $isFocused, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.font = font
        field.textColor = textColor
        field.tintColor = textColor
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.autocapitalizationType = autocapitalization
        field.autocorrectionType = autocorrection
        field.returnKeyType = returnKey
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: font]
        )
        field.addTarget(
            context.coordinator,
            action: #selector(SingleLineCoordinator.textFieldDidChange(_:)),
            for: .editingChanged
        )
        field.inputAccessoryView = makeDoneAccessoryView(
            target: field,
            action: #selector(UIResponder.resignFirstResponder)
        )
        // UITextField has its own intrinsic height; let SwiftUI size it natively.
        field.setContentHuggingPriority(.defaultHigh, for: .vertical)
        field.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.textBinding = $text
        context.coordinator.focusBinding = $isFocused
        context.coordinator.onSubmit = onSubmit

        if field.text != text { field.text = text }

        // Only push focus INTO the field. Outbound dismissal is owned by UIKit
        // (Done button → resignFirstResponder → textFieldDidEndEditing → binding
        // = false). Reconciling on a `false` snapshot here races with text-change
        // re-renders and dismisses the keyboard on every keystroke.
        if isFocused && !field.isFirstResponder {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        }
    }
}

@MainActor
final class SingleLineCoordinator: NSObject, UITextFieldDelegate {
    var textBinding: Binding<String>
    var focusBinding: Binding<Bool>
    var onSubmit: (() -> Void)?

    init(text: Binding<String>, isFocused: Binding<Bool>, onSubmit: (() -> Void)?) {
        self.textBinding = text
        self.focusBinding = isFocused
        self.onSubmit = onSubmit
    }

    @objc func textFieldDidChange(_ field: UITextField) {
        textBinding.wrappedValue = field.text ?? ""
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Mirror UIKit's resign back to the binding so consumers that watch
        // isFocused (e.g. for inline UI) see the change. Begin-editing has no
        // mirror: we let UIKit own focus once it has it, since echoing `true`
        // back causes a re-render race that resigns the field mid-keystroke.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.focusBinding.wrappedValue != false {
                self.focusBinding.wrappedValue = false
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSubmit?()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Multi-line bridge (UITextView)

struct BridgedMultiLineTextInput: UIViewRepresentable {
    typealias UIViewType = PlaceholderTextView

    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let maxLines: Int
    let font: UIFont
    let textColor: UIColor
    let placeholderColor: UIColor
    let autocapitalization: UITextAutocapitalizationType
    let autocorrection: UITextAutocorrectionType

    func makeCoordinator() -> MultiLineCoordinator {
        MultiLineCoordinator(text: $text, isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> PlaceholderTextView {
        let textView = PlaceholderTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.tintColor = textColor
        textView.backgroundColor = .clear
        textView.autocapitalizationType = autocapitalization
        textView.autocorrectionType = autocorrection
        textView.returnKeyType = .default
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.configurePlaceholder(text: placeholder, color: placeholderColor, font: font)
        textView.configureLineLimits(max: maxLines)
        textView.inputAccessoryView = makeDoneAccessoryView(
            target: textView,
            action: #selector(UIResponder.resignFirstResponder)
        )
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return textView
    }

    func updateUIView(_ textView: PlaceholderTextView, context: Context) {
        context.coordinator.textBinding = $text
        context.coordinator.focusBinding = $isFocused

        if textView.text != text {
            textView.text = text
            textView.refreshPlaceholderVisibility()
            textView.invalidateIntrinsicContentSize()
        }

        // Inbound focus only — see BridgedSingleLineTextInput.updateUIView.
        if isFocused && !textView.isFirstResponder {
            DispatchQueue.main.async { textView.becomeFirstResponder() }
        }
    }
}

@MainActor
final class MultiLineCoordinator: NSObject, UITextViewDelegate {
    var textBinding: Binding<String>
    var focusBinding: Binding<Bool>

    init(text: Binding<String>, isFocused: Binding<Bool>) {
        self.textBinding = text
        self.focusBinding = isFocused
    }

    func textViewDidChange(_ textView: UITextView) {
        textBinding.wrappedValue = textView.text ?? ""
        (textView as? PlaceholderTextView)?.refreshPlaceholderVisibility()
        textView.invalidateIntrinsicContentSize()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.focusBinding.wrappedValue != false {
                self.focusBinding.wrappedValue = false
            }
        }
    }
}

// MARK: - PlaceholderTextView (UITextView with placeholder + maxLines clamp)

final class PlaceholderTextView: UITextView {
    private let placeholderLabel = UILabel()
    private var maxLines: Int = .max
    private var lineHeight: CGFloat { font?.lineHeight ?? UIFont.systemFont(ofSize: 17).lineHeight }

    func configurePlaceholder(text: String, color: UIColor, font: UIFont) {
        placeholderLabel.text = text
        placeholderLabel.textColor = color
        placeholderLabel.font = font
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        refreshPlaceholderVisibility()
    }

    func configureLineLimits(max: Int) {
        self.maxLines = max
        isScrollEnabled = false
    }

    func refreshPlaceholderVisibility() {
        placeholderLabel.isHidden = !(text ?? "").isEmpty
    }

    override var intrinsicContentSize: CGSize {
        let oneLine = lineHeight
        let maxHeight = lineHeight * CGFloat(maxLines)
        let fittingWidth = bounds.width > 0 ? bounds.width : CGFloat.greatestFiniteMagnitude
        let fitting = sizeThatFits(CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)).height
        let height = Swift.max(oneLine, Swift.min(fitting, maxHeight))
        isScrollEnabled = fitting > maxHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}

// MARK: - Shared accessory bar

@MainActor
fileprivate func makeDoneAccessoryView(target: UIResponder, action: Selector) -> UIView {
    // Transparent bar so app content shows through; only the Done button is drawn.
    let bar = PassthroughAccessoryView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
    bar.backgroundColor = .clear
    bar.autoresizingMask = [.flexibleWidth]

    var buttonConfig = UIButton.Configuration.plain()
    buttonConfig.title = "Done"
    buttonConfig.baseForegroundColor = UIColor(Color.accent)
    buttonConfig.background.backgroundColor = UIColor(Color.accent.opacity(0.25))
    buttonConfig.background.cornerRadius = 16
    buttonConfig.background.strokeColor = UIColor(Color.accent.opacity(0.5))
    buttonConfig.background.strokeWidth = 1
    buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
    var titleAttributes = AttributeContainer()
    titleAttributes.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    buttonConfig.attributedTitle = AttributedString("Done", attributes: titleAttributes)

    let button = UIButton(configuration: buttonConfig)
    button.addTarget(target, action: action, for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false

    bar.addSubview(button)
    NSLayoutConstraint.activate([
        button.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -16),
        button.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
    ])
    return bar
}

/// inputAccessoryView container that doesn't intercept touches in its empty area,
/// so app content behind it remains tappable. Touches inside the Done button
/// still hit the button.
final class PassthroughAccessoryView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews where !subview.isHidden && subview.alpha > 0 {
            let converted = convert(point, to: subview)
            if subview.point(inside: converted, with: event) {
                return true
            }
        }
        return false
    }
}

// MARK: - SwiftUI wrappers (public call-site API)

struct BridgedTextField: View {
    @Binding var text: String
    var placeholder: String = ""
    @Binding var isFocused: Bool
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var autocorrection: UITextAutocorrectionType = .default
    var returnKey: UIReturnKeyType = .done
    var font: UIFont = .systemFont(ofSize: UIFont.systemFontSize)
    var textColor: Color = .textPrimary
    var placeholderColor: Color = .textTertiary
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        BridgedSingleLineTextInput(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            font: font,
            textColor: UIColor(textColor),
            placeholderColor: UIColor(placeholderColor),
            autocapitalization: autocapitalization,
            autocorrection: autocorrection,
            returnKey: returnKey,
            onSubmit: onSubmit
        )
    }
}

struct BridgedTextEditor: View {
    @Binding var text: String
    var placeholder: String = ""
    @Binding var isFocused: Bool
    var maxLines: Int = 5
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var autocorrection: UITextAutocorrectionType = .default
    var font: UIFont = .systemFont(ofSize: UIFont.systemFontSize)
    var textColor: Color = .textPrimary
    var placeholderColor: Color = .textTertiary

    var body: some View {
        BridgedMultiLineTextInput(
            text: $text,
            isFocused: $isFocused,
            placeholder: placeholder,
            maxLines: maxLines,
            font: font,
            textColor: UIColor(textColor),
            placeholderColor: UIColor(placeholderColor),
            autocapitalization: autocapitalization,
            autocorrection: autocorrection
        )
    }
}
