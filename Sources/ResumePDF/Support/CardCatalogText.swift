//
//  CardCatalogText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The card designs, as data, compiled in for the same reason the résumé
//  designs are.
//

enum CardCatalogText {

    /// Every file, by name, in the order they are listed.
    static let all: [(name: String, json: String)] = [
        ("plate", plate),
        ("reverse", reverse),
        ("portrait", portrait),
        ("minimal", minimal),
    ]

    static let plate = ##"""
    {
      "back": {
        "align": "centre",
        "anchor": "middle",
        "content": [
          "code"
        ],
        "fill": "ink",
        "padding": 17
      },
      "front": {
        "align": "left",
        "anchor": "middle",
        "content": [
          "name",
          "title",
          "organisation",
          "rule",
          "contacts"
        ],
        "fill": "page",
        "padding": 17
      },
      "name": "plate",
      "pairsWith": "ledger",
      "size": {
        "height": 155.90551181102364,
        "width": 240.9448818897638
      },
      "type": {
        "bodySize": 7.6,
        "codeSize": 74,
        "nameSize": 15,
        "nameWeight": "semibold",
        "titleColour": "accent",
        "titleSize": 8.2,
        "tracking": -0.2,
        "uppercase": false
      },
      "typeface": "sans"
    }

    """##

    static let reverse = ##"""
    {
      "back": {
        "align": "left",
        "anchor": "middle",
        "content": [
          "contacts",
          "space",
          "code"
        ],
        "fill": "page",
        "padding": 17
      },
      "front": {
        "align": "left",
        "anchor": "middle",
        "content": [
          "name",
          "title",
          "rule",
          "organisation"
        ],
        "fill": "ink",
        "padding": 18
      },
      "name": "reverse",
      "pairsWith": "banner",
      "size": {
        "height": 155.90551181102364,
        "width": 240.9448818897638
      },
      "type": {
        "bodySize": 7.6,
        "codeSize": 62,
        "nameSize": 17,
        "nameWeight": "semibold",
        "titleColour": "accent",
        "titleSize": 8.4,
        "tracking": -0.3,
        "uppercase": false
      },
      "typeface": "sans"
    }

    """##

    static let portrait = ##"""
    {
      "back": {
        "align": "centre",
        "anchor": "middle",
        "content": [
          "contacts",
          "space",
          "code"
        ],
        "fill": "wash",
        "padding": 16
      },
      "front": {
        "align": "left",
        "anchor": "middle",
        "content": [
          "portrait",
          "name",
          "title",
          "organisation"
        ],
        "fill": "page",
        "padding": 16
      },
      "name": "portrait",
      "pairsWith": "foyer",
      "photo": {
        "align": "left",
        "diameter": 52
      },
      "size": {
        "height": 155.90551181102364,
        "width": 240.9448818897638
      },
      "type": {
        "bodySize": 7.4,
        "codeSize": 66,
        "nameSize": 14,
        "nameWeight": "semibold",
        "titleColour": "accent",
        "titleSize": 8,
        "tracking": -0.2,
        "uppercase": false
      },
      "typeface": "sans"
    }

    """##

    static let minimal = ##"""
    {
      "back": {
        "align": "centre",
        "anchor": "middle",
        "content": [
          "organisation",
          "contacts",
          "space",
          "code"
        ],
        "fill": "page",
        "padding": 18
      },
      "front": {
        "align": "centre",
        "anchor": "middle",
        "content": [
          "name",
          "rule",
          "title"
        ],
        "fill": "page",
        "padding": 18
      },
      "name": "minimal",
      "pairsWith": "plain",
      "size": {
        "height": 155.90551181102364,
        "width": 240.9448818897638
      },
      "type": {
        "bodySize": 7.4,
        "codeSize": 58,
        "nameSize": 14,
        "nameWeight": "regular",
        "titleColour": "muted",
        "titleSize": 7.6,
        "tracking": 2.2,
        "uppercase": true
      },
      "typeface": "sans"
    }

    """##

}
