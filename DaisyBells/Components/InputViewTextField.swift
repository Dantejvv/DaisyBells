import SwiftUI
import UIKit

struct InputViewTextField<KeypadContent: View>: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let placeholder: String
    let textAlignment: NSTextAlignment
    let font: UIFont
    let textColor: UIColor
    let placeholderColor: UIColor
    let keypad: () -> KeypadContent

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = HostingInputTextField()
        field.delegate = context.coordinator
        field.textAlignment = textAlignment
        field.font = font
        field.textColor = textColor
        field.tintColor = textColor
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.smartInsertDeleteType = .no
        field.inputAccessoryView = nil
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: placeholderColor, .font: font]
        )
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)

        // Install the custom input view via a hosting controller.
        let host = UIHostingController(rootView: keypad())
        host.sizingOptions = [.intrinsicContentSize]
        host.view.backgroundColor = UIColor(Color.bgPrimary)
        context.coordinator.hostingController = host

        // Size the host's view to screen width with a fixed height.
        host.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 280)
        host.view.autoresizingMask = [.flexibleWidth]
        field.inputView = host.view

        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Refresh coordinator's bindings so delegate callbacks write to current state.
        context.coordinator.textBinding = $text
        context.coordinator.focusBinding = $isFocused

        // Re-render keypad with latest closures. The rootView swap propagates new
        // `canSameAsLast`, `canNext`, and updated `onDone` / `onNext` closures.
        context.coordinator.hostingController?.rootView = keypad()

        if uiView.text != text {
            uiView.text = text
        }

        // Sync first-responder state from SwiftUI focus.
        if isFocused && !uiView.isFirstResponder {
            print("[BRIDGE-UI] updateUIView: isFocused=true, becomeFirstResponder()")
            DispatchQueue.main.async {
                let became = uiView.becomeFirstResponder()
                print("[BRIDGE-UI] becomeFirstResponder returned \(became)")
            }
        } else if !isFocused && uiView.isFirstResponder {
            print("[BRIDGE-UI] updateUIView: isFocused=false, resignFirstResponder()")
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var textBinding: Binding<String>
        var focusBinding: Binding<Bool>
        var hostingController: UIHostingController<KeypadContent>?

        init(text: Binding<String>, isFocused: Binding<Bool>) {
            self.textBinding = text
            self.focusBinding = isFocused
        }

        @objc func textChanged(_ field: UITextField) {
            textBinding.wrappedValue = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            print("[BRIDGE-DEL] textFieldDidBeginEditing")
            DispatchQueue.main.async { [weak self] in
                if self?.focusBinding.wrappedValue != true {
                    self?.focusBinding.wrappedValue = true
                }
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            print("[BRIDGE-DEL] textFieldDidEndEditing")
            DispatchQueue.main.async { [weak self] in
                if self?.focusBinding.wrappedValue != false {
                    self?.focusBinding.wrappedValue = false
                }
            }
        }
    }
}

/// UITextField subclass that disables system text-input behaviors we don't want for numeric pills.
final class HostingInputTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(select(_:)) || action == #selector(selectAll(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
