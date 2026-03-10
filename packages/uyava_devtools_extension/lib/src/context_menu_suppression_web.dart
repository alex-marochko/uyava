// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

html.EventListener? _contextMenuListener;
html.EventListener? _pointerDownListener;
bool _installed = false;

void installBrowserContextMenuSuppressor() {
  if (_installed) {
    return;
  }
  _installed = true;
  _contextMenuListener ??= _onContextMenu;
  _pointerDownListener ??= _onPointerDown;

  html.document.addEventListener('contextmenu', _contextMenuListener!, true);
  html.document.addEventListener('pointerdown', _pointerDownListener!, true);
}

void disposeBrowserContextMenuSuppressor() {
  if (!_installed) {
    return;
  }
  _installed = false;
  if (_contextMenuListener != null) {
    html.document.removeEventListener(
      'contextmenu',
      _contextMenuListener!,
      true,
    );
  }
  if (_pointerDownListener != null) {
    html.document.removeEventListener(
      'pointerdown',
      _pointerDownListener!,
      true,
    );
  }
}

void _onContextMenu(html.Event event) {
  if (_shouldAllowDefaultMenu(event)) {
    return;
  }
  event.preventDefault();
}

void _onPointerDown(html.Event event) {
  if (event is! html.PointerEvent) {
    return;
  }
  final buttons = event.buttons ?? 0;
  final isSecondaryButton = (buttons & 0x02) != 0;
  final isCtrlPrimary = (buttons & 0x01) != 0 && event.ctrlKey;
  if (!isSecondaryButton && !isCtrlPrimary) {
    return;
  }
  if (_shouldAllowDefaultMenu(event)) {
    return;
  }
  event.preventDefault();
}

bool _shouldAllowDefaultMenu(html.Event event) {
  final target = event.target;
  if (target is! html.Element) {
    return false;
  }
  if (_isEditable(target)) {
    return true;
  }
  final allowAttr = target.closest('[data-allow-browser-context-menu="true"]');
  return allowAttr != null;
}

bool _isEditable(html.Element element) {
  final tag = element.tagName.toLowerCase();
  switch (tag) {
    case 'input':
    case 'textarea':
    case 'select':
      return true;
  }
  if (element is html.HtmlElement) {
    final mode = element.contentEditable;
    if (mode == 'true' || mode == 'plaintext-only') {
      return true;
    }
    final role = element.getAttribute('role');
    if (role != null && role.contains('textbox')) {
      return true;
    }
  }
  return false;
}
