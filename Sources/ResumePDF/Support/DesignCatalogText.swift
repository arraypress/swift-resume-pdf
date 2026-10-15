//
//  DesignCatalogText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The résumé designs, as data. Compiled in as strings rather than shipped as
//  resources: a resource bundle beside a Homebrew binary breaks when the binary
//  is reached through a symlink, and with these and the fonts gone this
//  package has none. Each is the JSON `resume designs --blueprint` prints;
//  a test checks every one reads strictly, under a kebab-case name that is
//  its own.
//

enum DesignCatalogText {

    /// Every file, by name, in the order they are listed.
    static let all: [(name: String, json: String)] = [
        ("ledger", ledger),
        ("broadsheet", broadsheet),
        ("timeline", timeline),
        ("sidebar", sidebar),
        ("margin", margin),
        ("nocturne", nocturne),
        ("eclipse", eclipse),
        ("bulletin", bulletin),
        ("marker", marker),
        ("slate", slate),
        ("card", card),
        ("terminal", terminal),
        ("banner", banner),
        ("gazette", gazette),
        ("plain", plain),
        ("register", register),
        ("plaqued", plaqued),
        ("carded", carded),
        ("split", split),
        ("wing", wing),
        ("foyer", foyer),
        ("pillar", pillar),
        ("flank", flank),
        ("marquee", marquee),
    ]

    static let ledger = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 13,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 7.6,
        "style" : "ruled"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25.5,
        "nameWeight" : "semibold",
        "qr" : 58,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.9,
          "underName" : false,
          "width" : 0
        },
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "ledger",
      "ornament" : "none",
      "sectionGap" : 17,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let broadsheet = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.7,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.5,
        "entryGap" : 14,
        "roleSize" : 10.6,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 8,
        "style" : "centred"
      },
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.8,
        "contacts" : "flow",
        "gapAfter" : 20,
        "headlineColour" : "muted",
        "headlineItalic" : true,
        "headlineSize" : 10.6,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 19,
        "nameWeight" : "regular",
        "qr" : 0,
        "rule" : {
          "colour" : "ink",
          "double" : true,
          "thickness" : 0.7,
          "underName" : false,
          "width" : 0
        },
        "separator" : "·",
        "tracking" : 2.2,
        "twin" : false,
        "uppercase" : true
      },
      "name" : "broadsheet",
      "ornament" : "none",
      "sectionGap" : 18,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "serif"
    }

    """##

    static let timeline = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : true,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 15,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 7.6,
        "style" : "accentBar"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.6,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "muted",
        "headlineItalic" : false,
        "headlineSize" : 10.5,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 24,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : {
          "colour" : "accent",
          "double" : false,
          "thickness" : 2,
          "underName" : false,
          "width" : 96
        },
        "separator" : "·",
        "tracking" : -0.35,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "timeline",
      "ornament" : "rail",
      "sectionGap" : 17,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let sidebar = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 7.6,
        "style" : "ruled"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25.5,
        "nameWeight" : "semibold",
        "photo" : {
          "align" : "right",
          "diameter" : 66
        },
        "qr" : 0,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.9,
          "underName" : false,
          "width" : 0
        },
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "sidebar",
      "ornament" : "none",
      "sectionGap" : 16,
      "sections" : {

      },
      "side" : {
        "divider" : false,
        "edge" : "left",
        "entries" : {
          "accentRoles" : false,
          "bodySize" : 8.7,
          "dateSize" : 8,
          "dates" : "beneath",
          "detailSize" : 8.6,
          "entryGap" : 10,
          "roleSize" : 9.6,
          "skills" : "list"
        },
        "fill" : "rail",
        "gutter" : 30,
        "head" : "inside",
        "heading" : {
          "colour" : "accent",
          "icon" : false,
          "size" : 7.4,
          "style" : "plain"
        },
        "inset" : 27,
        "sections" : [
          "skills",
          "languages",
          "education",
          "certifications",
          "interests"
        ],
        "width" : 190
      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let margin = ##"""
    {
      "column" : {
        "gutter" : 22,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 104,
        "ruled" : true
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 8.6,
        "style" : "margin"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "labelled",
        "gapAfter" : 6,
        "headlineColour" : "muted",
        "headlineItalic" : false,
        "headlineSize" : 10.4,
        "monospaced" : false,
        "nameColour" : "accent",
        "nameSize" : 23,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.3,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "margin",
      "ornament" : "none",
      "sectionGap" : 15,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let nocturne = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 7.6,
        "style" : "plain"
      },
      "masthead" : {
        "align" : "left",
        "body" : "inverse",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "muted",
        "headlineItalic" : false,
        "headlineSize" : 10.6,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25,
        "nameWeight" : "semibold",
        "photo" : {
          "align" : "right",
          "diameter" : 74
        },
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "nocturne",
      "ornament" : "none",
      "sectionGap" : 17,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let eclipse = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 7.6,
        "style" : "plain"
      },
      "masthead" : {
        "align" : "left",
        "band" : "darkest",
        "body" : "dark",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.6,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25,
        "nameWeight" : "semibold",
        "photo" : {
          "align" : "right",
          "diameter" : 74
        },
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "eclipse",
      "ornament" : "none",
      "sectionGap" : 17,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let bulletin = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "ink",
        "icon" : true,
        "size" : 8.2,
        "style" : "tab"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 16,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 11,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25,
        "nameWeight" : "semibold",
        "photo" : {
          "align" : "right",
          "diameter" : 78
        },
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "bulletin",
      "ornament" : "none",
      "sectionGap" : 16,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let marker = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 15,
        "roleSize" : 10.4,
        "skills" : "bars"
      },
      "footer" : true,
      "heading" : {
        "colour" : "ink",
        "icon" : false,
        "size" : 12,
        "style" : "marker"
      },
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 14,
        "headlineColour" : "muted",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 28,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : {
          "colour" : "accent",
          "double" : false,
          "thickness" : 2.6,
          "underName" : true,
          "width" : 0
        },
        "separator" : "▪",
        "tracking" : -0.5,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "marker",
      "ornament" : "none",
      "sectionGap" : 18,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let slate = ##"""
    {
      "column" : {
        "gutter" : 14,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 4,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 15,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 8.4,
        "style" : "plain"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 11,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : true,
        "uppercase" : false
      },
      "name" : "slate",
      "ornament" : "tabs",
      "sectionGap" : 16,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let card = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 12,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 8.2,
        "style" : "plain"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 14,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 11,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 26,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "card",
      "ornament" : "entryCards",
      "sectionGap" : 8,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let terminal = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 15,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "ink",
        "icon" : false,
        "size" : 8.2,
        "style" : "terminal"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.6,
        "contacts" : "flow",
        "gapAfter" : 18,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.4,
        "monospaced" : true,
        "nameColour" : "ink",
        "nameSize" : 23,
        "nameWeight" : "semibold",
        "qr" : 58,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 1,
          "underName" : false,
          "width" : 0
        },
        "separator" : "·",
        "tracking" : -0.9,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "terminal",
      "ornament" : "none",
      "sectionGap" : 17,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let banner = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "ink",
        "icon" : false,
        "size" : 7.8,
        "style" : "underlined"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 10,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 11.2,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 27,
        "nameWeight" : "semibold",
        "panel" : {
          "dip" : 0,
          "fill" : "ink",
          "height" : 120
        },
        "photo" : {
          "align" : "right",
          "diameter" : 84
        },
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "banner",
      "ornament" : "none",
      "sectionGap" : 16,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let gazette = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.6,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.4,
        "entryGap" : 14,
        "roleSize" : 10.6,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : false,
        "size" : 7.6,
        "style" : "ruled"
      },
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.8,
        "contacts" : "flow",
        "gapAfter" : 18,
        "headlineColour" : "muted",
        "headlineItalic" : true,
        "headlineSize" : 10.4,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 19,
        "nameWeight" : "regular",
        "qr" : 0,
        "rule" : {
          "colour" : "ink",
          "double" : false,
          "thickness" : 0.7,
          "underName" : false,
          "width" : 0
        },
        "separator" : "·",
        "tracking" : 2.2,
        "twin" : false,
        "uppercase" : true
      },
      "name" : "gazette",
      "ornament" : "none",
      "sectionGap" : 17,
      "sections" : {

      },
      "side" : {
        "divider" : true,
        "edge" : "right",
        "entries" : {
          "accentRoles" : false,
          "bodySize" : 8.8,
          "dateSize" : 8.2,
          "dates" : "beneath",
          "detailSize" : 8.8,
          "entryGap" : 10,
          "roleSize" : 9.4,
          "skills" : "list"
        },
        "fill" : null,
        "gutter" : 28,
        "head" : "above",
        "heading" : {
          "colour" : "muted",
          "icon" : false,
          "size" : 7.2,
          "style" : "plain"
        },
        "inset" : 27,
        "sections" : [
          "education",
          "skills",
          "certifications",
          "languages"
        ],
        "width" : 152
      },
      "skip" : [

      ],
      "typeface" : "serif"
    }

    """##

    static let plain = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 8.8,
        "dateSize" : 8.2,
        "dates" : "besideTitle",
        "detailSize" : 8.4,
        "entryGap" : 7,
        "roleSize" : 9.6,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "ink",
        "icon" : false,
        "size" : 9.6,
        "style" : "ruled"
      },
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.2,
        "contacts" : "flow",
        "gapAfter" : 10,
        "headlineColour" : "muted",
        "headlineItalic" : false,
        "headlineSize" : 9.6,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 22,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "plain",
      "ornament" : "none",
      "sectionGap" : 9,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let register = ##"""
    {
      "column" : {
        "gutter" : 20,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 96,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "list"
      },
      "footer" : true,
      "heading" : {
        "colour" : "muted",
        "icon" : true,
        "size" : 8.6,
        "style" : "margin"
      },
      "masthead" : {
        "align" : "centre",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 8,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 24,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.3,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "register",
      "ornament" : "bands",
      "sectionGap" : 15,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let plaqued = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 14,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 7.6,
        "style" : "accentBar"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 10,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 27,
        "nameWeight" : "semibold",
        "panel" : {
          "dip" : 26,
          "fill" : "accent",
          "height" : 172
        },
        "photo" : {
          "align" : "right",
          "diameter" : 66
        },
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "plaqued",
      "ornament" : "none",
      "sectionGap" : 16,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let carded = ##"""
    {
      "column" : {
        "gutter" : 0,
        "headAtMargin" : false,
        "labelAlign" : "right",
        "labelWidth" : 0,
        "ruled" : false
      },
      "entries" : {
        "accentRoles" : false,
        "bodySize" : 9.4,
        "dateSize" : 8.5,
        "dates" : "besideTitle",
        "detailSize" : 9.2,
        "entryGap" : 12,
        "roleSize" : 10.4,
        "skills" : "chips"
      },
      "footer" : true,
      "heading" : {
        "colour" : "accent",
        "icon" : false,
        "size" : 8.2,
        "style" : "plain"
      },
      "masthead" : {
        "align" : "left",
        "contactSize" : 8.7,
        "contacts" : "flow",
        "gapAfter" : 19,
        "headlineColour" : "accent",
        "headlineItalic" : false,
        "headlineSize" : 10.8,
        "monospaced" : false,
        "nameColour" : "ink",
        "nameSize" : 25,
        "nameWeight" : "semibold",
        "qr" : 0,
        "rule" : null,
        "separator" : "·",
        "tracking" : -0.4,
        "twin" : false,
        "uppercase" : false
      },
      "name" : "carded",
      "ornament" : "cards",
      "sectionGap" : 14,
      "sections" : {

      },
      "skip" : [

      ],
      "typeface" : "sans"
    }

    """##

    static let split = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": true,
        "bodySize": 9.2,
        "dateSize": 8.4,
        "dates": "besideTitle",
        "detailSize": 9.0,
        "entryGap": 13,
        "languages": "dots",
        "roleSize": 10.4,
        "skills": "list"
      },
      "footer": true,
      "heading": {
        "colour": "muted",
        "icon": false,
        "size": 7.6,
        "style": "ruled"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 14,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 11,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 27,
        "nameWeight": "semibold",
        "photo": {
          "align": "right",
          "diameter": 74
        },
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": 0.5,
        "twin": false,
        "uppercase": true
      },
      "name": "split",
      "ornament": "none",
      "sectionGap": 15,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "right",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "dots",
          "roleSize": 9.5,
          "skills": "underlined"
        },
        "fill": null,
        "gutter": 26,
        "head": "above",
        "heading": {
          "colour": "muted",
          "icon": false,
          "size": 7.4,
          "style": "ruled"
        },
        "inset": 0,
        "sections": [
          "summary",
          "strengths",
          "achievements",
          "skills",
          "certifications",
          "languages",
          "time",
          "interests"
        ],
        "width": 172
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

    static let wing = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": true,
        "bodySize": 9.2,
        "dateSize": 8.4,
        "dates": "besideTitle",
        "detailSize": 9.0,
        "entryGap": 13,
        "languages": "dots",
        "roleSize": 10.4,
        "skills": "underlined"
      },
      "footer": true,
      "heading": {
        "colour": "muted",
        "icon": false,
        "size": 7.6,
        "style": "ruled"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 14,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 11,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 28,
        "nameWeight": "semibold",
        "photo": {
          "align": "right",
          "diameter": 66
        },
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": 0.6,
        "twin": false,
        "uppercase": true
      },
      "name": "wing",
      "ornament": "none",
      "sectionGap": 15,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "left",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "dots",
          "roleSize": 9.5,
          "skills": "underlined"
        },
        "fill": null,
        "gutter": 28,
        "head": "above",
        "heading": {
          "colour": "muted",
          "icon": false,
          "size": 7.4,
          "style": "ruled"
        },
        "inset": 0,
        "sections": [
          "skills",
          "projects",
          "achievements",
          "certifications",
          "languages",
          "interests",
          "awards"
        ],
        "width": 150
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

    static let foyer = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": false,
        "bodySize": 9.2,
        "dateSize": 8.4,
        "dates": "besideTitle",
        "detailSize": 9.0,
        "entryGap": 13,
        "languages": "bars",
        "roleSize": 10.6,
        "skills": "list"
      },
      "footer": true,
      "heading": {
        "colour": "accent",
        "icon": true,
        "size": 8.4,
        "style": "plain"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 16,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 11.2,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 30,
        "nameWeight": "regular",
        "photo": {
          "align": "left",
          "diameter": 110
        },
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": -0.3,
        "twin": false,
        "uppercase": false
      },
      "name": "foyer",
      "ornament": "none",
      "sectionGap": 16,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "left",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "bars",
          "roleSize": 9.5,
          "skills": "list"
        },
        "fill": null,
        "gutter": 36,
        "head": "main",
        "heading": {
          "colour": "accent",
          "icon": false,
          "size": 7.6,
          "style": "plain"
        },
        "inset": 0,
        "sections": [
          "achievements",
          "certifications",
          "projects",
          "languages",
          "interests",
          "awards",
          "volunteering"
        ],
        "width": 150
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

    static let pillar = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": true,
        "bodySize": 9.2,
        "dateSize": 8.4,
        "dates": "besideTitle",
        "detailSize": 9.0,
        "entryGap": 13,
        "languages": "dots",
        "roleSize": 10.4,
        "skills": "list"
      },
      "footer": true,
      "heading": {
        "colour": "muted",
        "icon": false,
        "size": 7.8,
        "style": "ruled"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 16,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 11,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 27,
        "nameWeight": "semibold",
        "photo": {
          "align": "right",
          "diameter": 84
        },
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": 0.6,
        "twin": false,
        "uppercase": true
      },
      "name": "pillar",
      "ornament": "none",
      "sectionGap": 15,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "right",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "dots",
          "roleSize": 9.5,
          "skills": "list"
        },
        "fill": "ink",
        "gutter": 28,
        "head": "main",
        "heading": {
          "colour": "accent",
          "icon": false,
          "size": 7.4,
          "style": "ruled"
        },
        "inset": 26,
        "sections": [
          "achievements",
          "skills",
          "certifications",
          "languages",
          "interests",
          "awards"
        ],
        "width": 200
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

    static let flank = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": false,
        "bodySize": 9.4,
        "dateSize": 8.5,
        "dates": "besideTitle",
        "detailSize": 9.2,
        "entryGap": 14,
        "languages": "dots",
        "roleSize": 10.4,
        "skills": "inline"
      },
      "footer": true,
      "heading": {
        "colour": "muted",
        "icon": false,
        "size": 7.6,
        "style": "ruled"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 19,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 10.8,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 25.5,
        "nameWeight": "semibold",
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": -0.4,
        "twin": false,
        "uppercase": false
      },
      "name": "flank",
      "ornament": "none",
      "sectionGap": 16,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "left",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "dots",
          "roleSize": 9.5,
          "skills": "list"
        },
        "fill": "ink",
        "gutter": 30,
        "head": "inside",
        "heading": {
          "colour": "accent",
          "icon": false,
          "size": 7.6,
          "style": "plain"
        },
        "inset": 27,
        "sections": [
          "achievements",
          "certifications",
          "education",
          "languages",
          "interests",
          "awards"
        ],
        "width": 196
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

    static let marquee = ##"""
    {
      "column": {
        "gutter": 0,
        "headAtMargin": false,
        "labelAlign": "right",
        "labelWidth": 0,
        "ruled": false
      },
      "entries": {
        "accentRoles": true,
        "bodySize": 9.2,
        "dateSize": 8.4,
        "dates": "besideTitle",
        "detailSize": 9.0,
        "entryGap": 13,
        "languages": "dots",
        "roleSize": 10.4,
        "skills": "underlined"
      },
      "footer": true,
      "heading": {
        "colour": "accent",
        "icon": false,
        "size": 8,
        "style": "ruled"
      },
      "masthead": {
        "align": "left",
        "contactSize": 8.7,
        "contacts": "flow",
        "gapAfter": 12,
        "headlineColour": "accent",
        "headlineItalic": false,
        "headlineSize": 11.2,
        "monospaced": false,
        "nameColour": "ink",
        "nameSize": 27,
        "nameWeight": "semibold",
        "panel": {
          "dip": 0,
          "fill": "ink",
          "height": 110
        },
        "photo": {
          "align": "right",
          "diameter": 84
        },
        "qr": 0,
        "rule": null,
        "separator": "·",
        "tracking": -0.4,
        "twin": false,
        "uppercase": false
      },
      "name": "marquee",
      "ornament": "none",
      "sectionGap": 15,
      "sections": {},
      "side": {
        "divider": false,
        "edge": "right",
        "entries": {
          "accentRoles": false,
          "bodySize": 8.8,
          "dateSize": 8.1,
          "dates": "beneath",
          "detailSize": 8.7,
          "entryGap": 10,
          "languages": "dots",
          "roleSize": 9.5,
          "skills": "underlined"
        },
        "fill": null,
        "gutter": 26,
        "head": "above",
        "heading": {
          "colour": "accent",
          "icon": false,
          "size": 7.6,
          "style": "ruled"
        },
        "inset": 0,
        "sections": [
          "summary",
          "achievements",
          "certifications",
          "languages",
          "interests",
          "awards"
        ],
        "width": 176
      },
      "skip": [],
      "typeface": "sans"
    }

    """##

}
