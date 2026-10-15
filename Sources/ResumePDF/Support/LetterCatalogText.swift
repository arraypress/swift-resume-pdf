//
//  LetterCatalogText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The letter designs, as data, compiled in for the same reason the résumé
//  designs are.
//

enum LetterCatalogText {

    /// Every file, by name, in the order they are listed.
    static let all: [(name: String, json: String)] = [
        ("memo", memo),
        ("letterhead", letterhead),
        ("panel", panel),
        ("monogram", monogram),
    ]

    static let memo = ##"""
    {
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "finish" : "rule",
        "gapAfter" : 22,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.2,
        "nameBold" : true,
        "nameSize" : 22,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.9,
          "underName" : false,
          "width" : 0
        },
        "tracking" : -0.3,
        "uppercase" : false
      },
      "name" : "memo",
      "pairsWith" : "ledger",
      "typeface" : "sans"
    }

    """##

    static let letterhead = ##"""
    {
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.8,
        "contacts" : "ranged",
        "finish" : "rule",
        "gapAfter" : 24,
        "headlineColour" : "muted",
        "headlineItalic" : true,
        "headlineSize" : 11,
        "nameBold" : false,
        "nameSize" : 24,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.7,
          "underName" : false,
          "width" : 0
        },
        "tracking" : 0.2,
        "uppercase" : false
      },
      "name" : "letterhead",
      "pairsWith" : "broadsheet",
      "typeface" : "serif"
    }

    """##

    static let panel = ##"""
    {
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "panel",
        "finish" : "none",
        "gapAfter" : 22,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 11,
        "nameBold" : true,
        "nameSize" : 25,
        "photo" : {
          "align" : "right",
          "diameter" : 74
        },
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.9,
          "underName" : false,
          "width" : 0
        },
        "tracking" : -0.4,
        "uppercase" : false
      },
      "name" : "panel",
      "pairsWith" : "banner",
      "typeface" : "sans"
    }

    """##

    static let monogram = ##"""
    {
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "finish" : "capped",
        "gapAfter" : 20,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.6,
        "nameBold" : true,
        "nameSize" : 25,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.8,
          "underName" : false,
          "width" : 0
        },
        "tracking" : -0.3,
        "uppercase" : false
      },
      "name" : "monogram",
      "pairsWith" : "bulletin",
      "typeface" : "sans"
    }

    """##

}
