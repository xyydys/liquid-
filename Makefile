TARGET := iphone:clang:latest:26.0
ARCHS = arm64
THEOS_PACKAGE_SCHEME = rootless
FINALPACKAGE = 1
DEBUG = 0
INSTALL_TARGET_PROCESSES = LiquidGlassLab

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = LiquidGlassLab
LiquidGlassLab_FILES = main.m AppDelegate.m SceneDelegate.m LiquidGlassLabRoot.swift
LiquidGlassLab_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics
LiquidGlassLab_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
LiquidGlassLab_SWIFTFLAGS = -swift-version 5 -parse-as-library

include $(THEOS_MAKE_PATH)/application.mk
