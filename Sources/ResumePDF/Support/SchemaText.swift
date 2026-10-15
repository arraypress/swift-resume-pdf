//
//  SchemaText.swift
//  ResumePDF
//
//  Created by David Sherlock on 2026.
//
//  The JSON Schemas this library's files are written against, compiled in.
//  The theme's is DocumentTheme's.
//

enum SchemaText {

    /// Every file, by name, in the order they are listed.
    static let all: [(name: String, json: String)] = [
        ("resume", resume),
        ("letter", letter),
        ("blueprint", blueprint),
        ("letter-blueprint", letterBlueprint),
        ("card", card),
        ("card-blueprint", cardBlueprint),
    ]

    static let resume = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "$id": "https://github.com/arraypress/swift-resume-pdf/schemas/resume.schema.json",
      "title": "Résumé",
      "description": "A résumé or CV as swift-resume-pdf reads it. Only what identifies a thing is required; everything else defaults.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "profile": {
          "$ref": "#/$defs/profile"
        },
        "summary": {
          "type": "string"
        },
        "experience": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/position"
          }
        },
        "education": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/education"
          }
        },
        "skills": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/skillGroup"
          }
        },
        "projects": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/project"
          }
        },
        "volunteering": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/position"
          }
        },
        "certifications": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/credential"
          }
        },
        "publications": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/publication"
          }
        },
        "awards": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/award"
          }
        },
        "languages": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/language"
          }
        },
        "achievements": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/achievement"
          }
        },
        "strengths": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/strength"
          }
        },
        "time": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/timeSlice"
          }
        },
        "grants": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/grant"
          }
        },
        "teaching": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/position"
          }
        },
        "talks": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/publication"
          }
        },
        "service": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/position"
          }
        },
        "memberships": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/credential"
          }
        },
        "interests": {
          "type": "string"
        },
        "references": {
          "type": "string"
        },
        "custom": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/customSection"
          }
        },
        "order": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/sectionName"
          },
          "description": "The sections in the order they are drawn. A section with no place here is not drawn."
        },
        "labels": {
          "$ref": "#/$defs/labels"
        },
        "design": {
          "type": "string",
          "description": "A built-in design by name, or a path to a blueprint. Read by the tool; the library ignores it."
        },
        "letterDesign": {
          "type": "string",
          "description": "For a letter beside this résumé."
        },
        "theme": {
          "$ref": "#/$defs/themeSpec"
        },
        "extends": {
          "type": "string",
          "description": "Another spec this one inherits from, resolved from this file's folder. Read by the tool."
        }
      },
      "$defs": {
        "profile": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "headline": {
              "type": "string",
              "description": "The role, under the name."
            },
            "location": {
              "type": "string",
              "description": "A city and country."
            },
            "email": {
              "type": "string"
            },
            "phone": {
              "type": "string"
            },
            "links": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/link"
              }
            },
            "photo": {
              "type": "string",
              "description": "A path to a JPEG or PNG."
            },
            "qr": {
              "type": "string",
              "description": "An address to print as a code, in the designs that place one."
            },
            "dateOfBirth": {
              "type": "string",
              "description": "A Lebenslauf carries one; a US résumé must not."
            },
            "nationality": {
              "type": "string"
            },
            "maritalStatus": {
              "type": "string"
            },
            "placeOfBirth": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "dateRange": {
          "description": "A start and an end, or one date. Strings, because formatting a date means knowing a locale's conventions; `check` reports the ones without a four-digit year.",
          "oneOf": [
            {
              "type": "string",
              "description": "A single date, such as \"2023\" or \"Mar 2022\"."
            },
            {
              "type": "object",
              "properties": {
                "start": {
                  "type": "string"
                },
                "end": {
                  "type": "string",
                  "description": "Empty for a single date; \"Present\" for a position that has not ended."
                }
              },
              "additionalProperties": false
            }
          ]
        },
        "link": {
          "description": "An address. A bare string prints as the address shortened; an object names the label.",
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "url": {
                  "type": "string"
                },
                "label": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": [
                "url"
              ]
            }
          ]
        },
        "skill": {
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                },
                "level": {
                  "type": "number",
                  "description": "0 to 1, for the designs that draw bars or dots."
                }
              },
              "additionalProperties": false,
              "required": [
                "name"
              ]
            }
          ]
        },
        "position": {
          "type": "object",
          "properties": {
            "role": {
              "type": "string",
              "description": "The title held."
            },
            "organisation": {
              "type": "string"
            },
            "location": {
              "type": "string",
              "description": "A city, not an address."
            },
            "dates": {
              "$ref": "#/$defs/dateRange"
            },
            "summary": {
              "type": "string",
              "description": "One line about the role or the company."
            },
            "highlights": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "description": "What was actually achieved, one per line."
            },
            "skills": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "description": "Technologies or methods, where a design shows them separately."
            }
          },
          "additionalProperties": false,
          "required": [
            "role"
          ]
        },
        "education": {
          "type": "object",
          "properties": {
            "qualification": {
              "type": "string"
            },
            "institution": {
              "type": "string"
            },
            "location": {
              "type": "string"
            },
            "dates": {
              "$ref": "#/$defs/dateRange"
            },
            "grade": {
              "type": "string"
            },
            "highlights": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          },
          "additionalProperties": false,
          "required": [
            "qualification"
          ]
        },
        "project": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "role": {
              "type": "string"
            },
            "link": {
              "$ref": "#/$defs/link"
            },
            "dates": {
              "$ref": "#/$defs/dateRange"
            },
            "summary": {
              "type": "string"
            },
            "highlights": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "skills": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "skillGroup": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "items": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/skill"
              }
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "credential": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "issuer": {
              "type": "string"
            },
            "date": {
              "type": "string"
            },
            "identifier": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "publication": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string"
            },
            "venue": {
              "type": "string"
            },
            "date": {
              "type": "string"
            },
            "authors": {
              "type": "string"
            },
            "link": {
              "$ref": "#/$defs/link"
            }
          },
          "additionalProperties": false,
          "required": [
            "title"
          ]
        },
        "award": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "issuer": {
              "type": "string"
            },
            "date": {
              "type": "string"
            },
            "summary": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "language": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "level": {
              "type": "string",
              "description": "\"Native\", \"C1\", \"Conversational\" — printed as written."
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "grant": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string"
            },
            "funder": {
              "type": "string"
            },
            "amount": {
              "type": "string"
            },
            "dates": {
              "$ref": "#/$defs/dateRange"
            },
            "role": {
              "type": "string",
              "description": "\"PI\", \"Co-I\"."
            },
            "identifier": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "title"
          ]
        },
        "content": {
          "description": "One block of a custom section, named by its kind. Exactly one key.",
          "oneOf": [
            {
              "type": "object",
              "properties": {
                "prose": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": [
                "prose"
              ]
            },
            {
              "type": "object",
              "properties": {
                "list": {
                  "type": "array",
                  "items": {
                    "type": "string"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "list"
              ]
            },
            {
              "type": "object",
              "properties": {
                "positions": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/position"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "positions"
              ]
            },
            {
              "type": "object",
              "properties": {
                "education": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/education"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "education"
              ]
            },
            {
              "type": "object",
              "properties": {
                "projects": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/project"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "projects"
              ]
            },
            {
              "type": "object",
              "properties": {
                "publications": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/publication"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "publications"
              ]
            },
            {
              "type": "object",
              "properties": {
                "credentials": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/credential"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "credentials"
              ]
            },
            {
              "type": "object",
              "properties": {
                "awards": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/award"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "awards"
              ]
            },
            {
              "type": "object",
              "properties": {
                "grants": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/grant"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "grants"
              ]
            },
            {
              "type": "object",
              "properties": {
                "skills": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/skillGroup"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "skills"
              ]
            },
            {
              "type": "object",
              "properties": {
                "languages": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/language"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "languages"
              ]
            },
            {
              "type": "object",
              "properties": {
                "achievements": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/achievement"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "achievements"
              ]
            },
            {
              "type": "object",
              "properties": {
                "strengths": {
                  "type": "array",
                  "items": {
                    "$ref": "#/$defs/strength"
                  }
                }
              },
              "additionalProperties": false,
              "required": [
                "strengths"
              ]
            }
          ]
        },
        "customSection": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string"
            },
            "content": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/content"
              }
            }
          },
          "additionalProperties": false,
          "required": [
            "title"
          ]
        },
        "labels": {
          "description": "The section headings and the few words a design has to print. A language code, or the words spelled out.",
          "oneOf": [
            {
              "type": "string",
              "enum": [
                "en",
                "de"
              ]
            },
            {
              "type": "object",
              "properties": {
                "overrides": {
                  "type": "object",
                  "description": "A heading per section, keyed by section name.",
                  "propertyNames": {
                    "type": "string",
                    "enum": [
                      "summary",
                      "experience",
                      "education",
                      "skills",
                      "projects",
                      "volunteering",
                      "certifications",
                      "publications",
                      "awards",
                      "languages",
                      "grants",
                      "teaching",
                      "talks",
                      "service",
                      "memberships",
                      "interests",
                      "references",
                      "achievements",
                      "strengths",
                      "time"
                    ]
                  },
                  "additionalProperties": {
                    "type": "string"
                  }
                },
                "present": {
                  "type": "string",
                  "description": "The word for a position that has not ended."
                },
                "dateSeparator": {
                  "type": "string"
                },
                "language": {
                  "type": "string",
                  "description": "ISO 639-1."
                },
                "contact": {
                  "type": "string",
                  "description": "The word beside the contact details, where a design labels them."
                },
                "details": {
                  "type": "string",
                  "description": "The word beside the regional particulars."
                }
              },
              "additionalProperties": false
            }
          ]
        },
        "sectionName": {
          "description": "A built-in section, or `custom:<title>` for one of your own.",
          "anyOf": [
            {
              "type": "string",
              "enum": [
                "summary",
                "experience",
                "education",
                "skills",
                "projects",
                "volunteering",
                "certifications",
                "publications",
                "awards",
                "languages",
                "grants",
                "teaching",
                "talks",
                "service",
                "memberships",
                "interests",
                "references",
                "achievements",
                "strengths",
                "time"
              ]
            },
            {
              "type": "string",
              "pattern": "^custom:.+$"
            }
          ]
        },
        "themeSpec": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "typeface": {
              "description": "A bundled family by name, or a family of your own by its files.",
              "oneOf": [
                {
                  "type": "string",
                  "enum": [
                    "inter",
                    "sans",
                    "sourceSerif",
                    "serif"
                  ]
                },
                {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "name"
                  ],
                  "properties": {
                    "name": {
                      "type": "string",
                      "description": "For diagnostics."
                    },
                    "files": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "path"
                        ],
                        "properties": {
                          "path": {
                            "type": "string",
                            "description": "A static TrueType file, relative to the file that names it."
                          },
                          "weight": {
                            "type": "integer",
                            "minimum": 100,
                            "maximum": 900,
                            "description": "400 when absent."
                          },
                          "italic": {
                            "type": "boolean",
                            "description": "false when absent."
                          }
                        }
                      }
                    },
                    "bundled": {
                      "type": [
                        "string",
                        "null"
                      ]
                    }
                  }
                }
              ]
            },
            "accent": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Brand colour as hex, such as #1F3A5F."
            },
            "pageSize": {
              "type": "string",
              "enum": [
                "A4",
                "A5",
                "Letter",
                "Legal"
              ],
              "description": "Matched without regard to case."
            },
            "density": {
              "type": "string",
              "enum": [
                "relaxed",
                "normal",
                "compact"
              ]
            },
            "justified": {
              "type": "boolean",
              "description": "Whether body prose is set flush to both edges."
            },
            "scheme": {
              "type": "string",
              "enum": [
                "light",
                "dark"
              ],
              "description": "Résumés, letters and cards."
            },
            "tint": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Hex; the page painted this. Résumés, letters and cards."
            },
            "logo": {
              "type": "string",
              "description": "A PNG or JPEG for the designs with a place for one, relative to the file that names it. Markdown documents."
            }
          },
          "description": "The theme (the shape swift-document-theme defines, shared with press), laid over --theme; --var beats it. Paths are relative to this file."
        },
        "achievement": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string"
            },
            "summary": {
              "type": "string"
            },
            "icon": {
              "type": "string",
              "description": "star, flag, bolt, check, diamond, or a section's mark. Empty takes the next in a cycle."
            }
          },
          "additionalProperties": false,
          "required": [
            "title"
          ]
        },
        "strength": {
          "type": "object",
          "properties": {
            "title": {
              "type": "string"
            },
            "summary": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "title"
          ]
        },
        "timeSlice": {
          "type": "object",
          "properties": {
            "label": {
              "type": "string"
            },
            "share": {
              "type": "number",
              "description": "A weight, not a percentage: 3, 2, 1 and 50, 33, 17 draw the same ring."
            }
          },
          "additionalProperties": false,
          "required": [
            "label"
          ]
        }
      }
    }

    """##

    static let letter = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "$id": "https://github.com/arraypress/swift-resume-pdf/schemas/letter.schema.json",
      "title": "Cover letter",
      "description": "A covering letter as swift-resume-pdf reads it. The greeting and the sign-off are worked out when they are not given.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "profile": {
          "$ref": "#/$defs/profile"
        },
        "recipient": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "role": {
              "type": "string"
            },
            "organisation": {
              "type": "string"
            },
            "address": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          },
          "additionalProperties": false
        },
        "date": {
          "type": "string",
          "description": "As written; not formatted."
        },
        "subject": {
          "type": "string"
        },
        "salutation": {
          "type": "string",
          "description": "Overrides the greeting worked out from the recipient."
        },
        "body": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Paragraphs."
        },
        "highlights": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string"
              },
              "detail": {
                "type": "string"
              }
            },
            "additionalProperties": false,
            "required": [
              "title",
              "detail"
            ]
          }
        },
        "closing": {
          "type": "string",
          "description": "Overrides the sign-off."
        },
        "signature": {
          "type": "string",
          "description": "Overrides the signed name."
        },
        "postscript": {
          "type": "string"
        },
        "design": {
          "type": "string",
          "description": "A letter design by name, or a path to a letter blueprint. Read by the tool."
        },
        "letterDesign": {
          "type": "string"
        },
        "theme": {
          "$ref": "#/$defs/themeSpec"
        },
        "extends": {
          "type": "string"
        }
      },
      "$defs": {
        "profile": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "headline": {
              "type": "string",
              "description": "The role, under the name."
            },
            "location": {
              "type": "string",
              "description": "A city and country."
            },
            "email": {
              "type": "string"
            },
            "phone": {
              "type": "string"
            },
            "links": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/link"
              }
            },
            "photo": {
              "type": "string",
              "description": "A path to a JPEG or PNG."
            },
            "qr": {
              "type": "string",
              "description": "An address to print as a code, in the designs that place one."
            },
            "dateOfBirth": {
              "type": "string",
              "description": "A Lebenslauf carries one; a US résumé must not."
            },
            "nationality": {
              "type": "string"
            },
            "maritalStatus": {
              "type": "string"
            },
            "placeOfBirth": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "link": {
          "description": "An address. A bare string prints as the address shortened; an object names the label.",
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "url": {
                  "type": "string"
                },
                "label": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": [
                "url"
              ]
            }
          ]
        },
        "themeSpec": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "typeface": {
              "description": "A bundled family by name, or a family of your own by its files.",
              "oneOf": [
                {
                  "type": "string",
                  "enum": [
                    "inter",
                    "sans",
                    "sourceSerif",
                    "serif"
                  ]
                },
                {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "name"
                  ],
                  "properties": {
                    "name": {
                      "type": "string",
                      "description": "For diagnostics."
                    },
                    "files": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "path"
                        ],
                        "properties": {
                          "path": {
                            "type": "string",
                            "description": "A static TrueType file, relative to the file that names it."
                          },
                          "weight": {
                            "type": "integer",
                            "minimum": 100,
                            "maximum": 900,
                            "description": "400 when absent."
                          },
                          "italic": {
                            "type": "boolean",
                            "description": "false when absent."
                          }
                        }
                      }
                    },
                    "bundled": {
                      "type": [
                        "string",
                        "null"
                      ]
                    }
                  }
                }
              ]
            },
            "accent": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Brand colour as hex, such as #1F3A5F."
            },
            "pageSize": {
              "type": "string",
              "enum": [
                "A4",
                "A5",
                "Letter",
                "Legal"
              ],
              "description": "Matched without regard to case."
            },
            "density": {
              "type": "string",
              "enum": [
                "relaxed",
                "normal",
                "compact"
              ]
            },
            "justified": {
              "type": "boolean",
              "description": "Whether body prose is set flush to both edges."
            },
            "scheme": {
              "type": "string",
              "enum": [
                "light",
                "dark"
              ],
              "description": "Résumés, letters and cards."
            },
            "tint": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Hex; the page painted this. Résumés, letters and cards."
            },
            "logo": {
              "type": "string",
              "description": "A PNG or JPEG for the designs with a place for one, relative to the file that names it. Markdown documents."
            }
          },
          "description": "The theme (the shape swift-document-theme defines, shared with press), laid over --theme; --var beats it. Paths are relative to this file."
        }
      }
    }

    """##

    static let blueprint = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "$id": "https://github.com/arraypress/swift-resume-pdf/schemas/blueprint.schema.json",
      "title": "Résumé design",
      "description": "A résumé design written as data. Name only what you want changed; everything else takes the default.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        },
        "typeface": {
          "type": "string",
          "enum": [
            "sans",
            "serif"
          ]
        },
        "masthead": {
          "type": "object",
          "properties": {
            "align": {
              "$ref": "#/$defs/alignment"
            },
            "nameSize": {
              "type": "number"
            },
            "uppercase": {
              "type": "boolean"
            },
            "tracking": {
              "type": "number"
            },
            "headlineSize": {
              "type": "number"
            },
            "headlineColour": {
              "$ref": "#/$defs/paint"
            },
            "contactSize": {
              "type": "number"
            },
            "panel": {
              "type": "object",
              "properties": {
                "fill": {
                  "$ref": "#/$defs/paint"
                },
                "height": {
                  "type": "number"
                },
                "dip": {
                  "type": "number",
                  "description": "0 for a straight edge; larger for the shallow V."
                }
              },
              "additionalProperties": false
            },
            "photo": {
              "type": "object",
              "properties": {
                "diameter": {
                  "type": "number"
                },
                "align": {
                  "$ref": "#/$defs/alignment"
                }
              },
              "additionalProperties": false
            },
            "qr": {
              "type": "number",
              "description": "Size of the code beside the name; 0 for none."
            },
            "rule": {
              "oneOf": [
                {
                  "type": "object",
                  "properties": {
                    "colour": {
                      "$ref": "#/$defs/paint"
                    },
                    "thickness": {
                      "type": "number"
                    },
                    "double": {
                      "type": "boolean",
                      "description": "A hairline under the rule as well."
                    },
                    "width": {
                      "type": "number",
                      "description": "Points; 0 is the whole column."
                    },
                    "underName": {
                      "type": "boolean",
                      "description": "Under the name and as wide as it."
                    }
                  },
                  "additionalProperties": false
                },
                {
                  "type": "null"
                }
              ]
            },
            "monospaced": {
              "type": "boolean"
            },
            "gapAfter": {
              "type": "number"
            },
            "nameWeight": {
              "type": "string",
              "enum": [
                "regular",
                "semibold"
              ]
            },
            "nameColour": {
              "$ref": "#/$defs/paint"
            },
            "headlineItalic": {
              "type": "boolean"
            },
            "separator": {
              "type": "string"
            },
            "contacts": {
              "type": "string",
              "enum": [
                "flow",
                "labelled"
              ]
            },
            "twin": {
              "type": "boolean",
              "description": "Two panels under the name: the summary and the contacts."
            },
            "body": {
              "$ref": "#/$defs/paint"
            },
            "band": {
              "$ref": "#/$defs/paint"
            }
          },
          "additionalProperties": false
        },
        "column": {
          "type": "object",
          "properties": {
            "labelWidth": {
              "type": "number"
            },
            "gutter": {
              "type": "number"
            },
            "labelAlign": {
              "$ref": "#/$defs/alignment"
            },
            "headAtMargin": {
              "type": "boolean"
            },
            "ruled": {
              "type": "boolean"
            }
          },
          "additionalProperties": false
        },
        "heading": {
          "type": "object",
          "properties": {
            "style": {
              "type": "string",
              "enum": [
                "ruled",
                "plain",
                "accentBar",
                "centred",
                "tab",
                "marker",
                "margin",
                "terminal",
                "underlined"
              ]
            },
            "size": {
              "type": "number"
            },
            "colour": {
              "$ref": "#/$defs/paint"
            },
            "icon": {
              "type": "boolean"
            }
          },
          "additionalProperties": false
        },
        "entries": {
          "type": "object",
          "properties": {
            "dates": {
              "type": "string",
              "enum": [
                "besideTitle",
                "beneath"
              ]
            },
            "roleSize": {
              "type": "number"
            },
            "bodySize": {
              "type": "number"
            },
            "detailSize": {
              "type": "number"
            },
            "dateSize": {
              "type": "number"
            },
            "entryGap": {
              "type": "number"
            },
            "accentRoles": {
              "type": "boolean"
            },
            "skills": {
              "type": "string",
              "enum": [
                "list",
                "chips",
                "bars",
                "dots",
                "underlined",
                "inline"
              ]
            },
            "languages": {
              "type": "string",
              "enum": [
                "text",
                "dots",
                "bars"
              ]
            }
          },
          "additionalProperties": false
        },
        "ornament": {
          "type": "string",
          "enum": [
            "none",
            "bands",
            "cards",
            "entryCards",
            "rail",
            "tabs"
          ]
        },
        "sectionGap": {
          "type": "number"
        },
        "footer": {
          "type": "boolean"
        },
        "skip": {
          "type": "array",
          "items": {
            "$ref": "#/$defs/sectionName"
          }
        },
        "palette": {
          "type": "object",
          "properties": {
            "page": {
              "$ref": "#/$defs/paint"
            },
            "ink": {
              "$ref": "#/$defs/paint"
            },
            "muted": {
              "$ref": "#/$defs/paint"
            },
            "hairline": {
              "$ref": "#/$defs/paint"
            },
            "wash": {
              "$ref": "#/$defs/paint"
            },
            "accent": {
              "$ref": "#/$defs/paint"
            }
          },
          "additionalProperties": false
        },
        "sections": {
          "type": "object",
          "description": "Overrides for one section only.",
          "propertyNames": {
            "$ref": "#/$defs/sectionName"
          },
          "additionalProperties": {
            "type": "object",
            "properties": {
              "heading": {
                "type": "object",
                "properties": {
                  "style": {
                    "type": "string",
                    "enum": [
                      "ruled",
                      "plain",
                      "accentBar",
                      "centred",
                      "tab",
                      "marker",
                      "margin",
                      "terminal",
                      "underlined"
                    ]
                  },
                  "size": {
                    "type": "number"
                  },
                  "colour": {
                    "$ref": "#/$defs/paint"
                  },
                  "icon": {
                    "type": "boolean"
                  }
                },
                "additionalProperties": false
              },
              "entries": {
                "type": "object",
                "properties": {
                  "dates": {
                    "type": "string",
                    "enum": [
                      "besideTitle",
                      "beneath"
                    ]
                  },
                  "roleSize": {
                    "type": "number"
                  },
                  "bodySize": {
                    "type": "number"
                  },
                  "detailSize": {
                    "type": "number"
                  },
                  "dateSize": {
                    "type": "number"
                  },
                  "entryGap": {
                    "type": "number"
                  },
                  "accentRoles": {
                    "type": "boolean"
                  },
                  "skills": {
                    "type": "string",
                    "enum": [
                      "list",
                      "chips",
                      "bars",
                      "dots",
                      "underlined",
                      "inline"
                    ]
                  },
                  "languages": {
                    "type": "string",
                    "enum": [
                      "text",
                      "dots",
                      "bars"
                    ]
                  }
                },
                "additionalProperties": false
              },
              "sectionGap": {
                "type": "number"
              }
            },
            "additionalProperties": false
          }
        },
        "side": {
          "type": "object",
          "properties": {
            "width": {
              "type": "number"
            },
            "edge": {
              "type": "string",
              "enum": [
                "left",
                "right"
              ]
            },
            "sections": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/sectionName"
              }
            },
            "fill": {
              "oneOf": [
                {
                  "$ref": "#/$defs/paint"
                },
                {
                  "type": "null"
                }
              ]
            },
            "divider": {
              "type": "boolean"
            },
            "inset": {
              "type": "number"
            },
            "gutter": {
              "type": "number"
            },
            "head": {
              "type": "string",
              "enum": [
                "inside",
                "above",
                "main"
              ]
            },
            "heading": {
              "type": "object",
              "properties": {
                "style": {
                  "type": "string",
                  "enum": [
                    "ruled",
                    "plain",
                    "accentBar",
                    "centred",
                    "tab",
                    "marker",
                    "margin",
                    "terminal",
                    "underlined"
                  ]
                },
                "size": {
                  "type": "number"
                },
                "colour": {
                  "$ref": "#/$defs/paint"
                },
                "icon": {
                  "type": "boolean"
                }
              },
              "additionalProperties": false
            },
            "entries": {
              "type": "object",
              "properties": {
                "dates": {
                  "type": "string",
                  "enum": [
                    "besideTitle",
                    "beneath"
                  ]
                },
                "roleSize": {
                  "type": "number"
                },
                "bodySize": {
                  "type": "number"
                },
                "detailSize": {
                  "type": "number"
                },
                "dateSize": {
                  "type": "number"
                },
                "entryGap": {
                  "type": "number"
                },
                "accentRoles": {
                  "type": "boolean"
                },
                "skills": {
                  "type": "string",
                  "enum": [
                    "list",
                    "chips",
                    "bars",
                    "dots",
                    "underlined",
                    "inline"
                  ]
                },
                "languages": {
                  "type": "string",
                  "enum": [
                    "text",
                    "dots",
                    "bars"
                  ]
                }
              },
              "additionalProperties": false
            }
          },
          "additionalProperties": false,
          "description": "A second column. The one thing a tracking system reads wrong; `check` says so."
        }
      },
      "$defs": {
        "paint": {
          "description": "A named colour that follows the theme, or hex.",
          "anyOf": [
            {
              "type": "string",
              "enum": [
                "ink",
                "muted",
                "accent",
                "hairline",
                "wash",
                "page",
                "rail",
                "inverse",
                "dark",
                "darkest"
              ]
            },
            {
              "type": "string",
              "pattern": "^#[0-9A-Fa-f]{6}$"
            }
          ]
        },
        "alignment": {
          "type": "string",
          "enum": [
            "left",
            "centre",
            "right"
          ]
        },
        "sectionName": {
          "description": "A built-in section, or `custom:<title>` for one of your own.",
          "anyOf": [
            {
              "type": "string",
              "enum": [
                "summary",
                "experience",
                "education",
                "skills",
                "projects",
                "volunteering",
                "certifications",
                "publications",
                "awards",
                "languages",
                "grants",
                "teaching",
                "talks",
                "service",
                "memberships",
                "interests",
                "references",
                "achievements",
                "strengths",
                "time"
              ]
            },
            {
              "type": "string",
              "pattern": "^custom:.+$"
            }
          ]
        }
      }
    }

    """##

    static let letterBlueprint = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "$id": "https://github.com/arraypress/swift-resume-pdf/schemas/letter-blueprint.schema.json",
      "title": "Letter design",
      "description": "A letter design written as data. Only the masthead is yours to set; the body of a letter is not a setting.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        },
        "pairsWith": {
          "type": "string",
          "description": "The résumé design it sits beside."
        },
        "typeface": {
          "type": "string",
          "enum": [
            "sans",
            "serif"
          ]
        },
        "masthead": {
          "type": "object",
          "properties": {
            "align": {
              "$ref": "#/$defs/alignment"
            },
            "nameSize": {
              "type": "number"
            },
            "uppercase": {
              "type": "boolean"
            },
            "tracking": {
              "type": "number"
            },
            "nameBold": {
              "type": "boolean"
            },
            "headlineSize": {
              "type": "number"
            },
            "headlineColour": {
              "$ref": "#/$defs/paint"
            },
            "headlineItalic": {
              "type": "boolean"
            },
            "contacts": {
              "type": "string",
              "enum": [
                "flow",
                "ranged",
                "panel",
                "none"
              ]
            },
            "contactSize": {
              "type": "number"
            },
            "photo": {
              "type": "object",
              "properties": {
                "diameter": {
                  "type": "number"
                },
                "align": {
                  "$ref": "#/$defs/alignment"
                }
              },
              "additionalProperties": false
            },
            "finish": {
              "type": "string",
              "enum": [
                "rule",
                "capped",
                "none"
              ]
            },
            "rule": {
              "type": "object",
              "properties": {
                "colour": {
                  "$ref": "#/$defs/paint"
                },
                "thickness": {
                  "type": "number"
                },
                "double": {
                  "type": "boolean",
                  "description": "A hairline under the rule as well."
                },
                "width": {
                  "type": "number",
                  "description": "Points; 0 is the whole column."
                },
                "underName": {
                  "type": "boolean",
                  "description": "Under the name and as wide as it."
                }
              },
              "additionalProperties": false
            },
            "gapAfter": {
              "type": "number"
            }
          },
          "additionalProperties": false
        }
      },
      "$defs": {
        "paint": {
          "description": "A named colour that follows the theme, or hex.",
          "anyOf": [
            {
              "type": "string",
              "enum": [
                "ink",
                "muted",
                "accent",
                "hairline",
                "wash",
                "page",
                "rail",
                "inverse",
                "dark",
                "darkest"
              ]
            },
            {
              "type": "string",
              "pattern": "^#[0-9A-Fa-f]{6}$"
            }
          ]
        },
        "alignment": {
          "type": "string",
          "enum": [
            "left",
            "centre",
            "right"
          ]
        }
      }
    }

    """##

    static let card = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "title": "Business card",
      "description": "A business card: a profile, and the two facts a résumé keeps elsewhere.",
      "type": "object",
      "required": [
        "profile"
      ],
      "additionalProperties": false,
      "properties": {
        "profile": {
          "$ref": "#/$defs/profile"
        },
        "organisation": {
          "type": "string",
          "description": "The employer, which a résumé keeps in its experience."
        },
        "title": {
          "type": "string",
          "description": "Printed under the name. Empty takes the profile's headline, which is often too long for 85mm."
        },
        "tagline": {
          "type": "string",
          "description": "A line for the back, where a design has one."
        },
        "code": {
          "type": "string",
          "description": "What the scannable code says. Empty encodes a vCard built from the profile."
        },
        "design": {
          "type": "string",
          "description": "Which card design, or a path to a card blueprint."
        },
        "theme": {
          "$ref": "#/$defs/themeSpec"
        }
      },
      "$defs": {
        "profile": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "headline": {
              "type": "string",
              "description": "The role, under the name."
            },
            "location": {
              "type": "string",
              "description": "A city and country."
            },
            "email": {
              "type": "string"
            },
            "phone": {
              "type": "string"
            },
            "links": {
              "type": "array",
              "items": {
                "$ref": "#/$defs/link"
              }
            },
            "photo": {
              "type": "string",
              "description": "A path to a JPEG or PNG."
            },
            "qr": {
              "type": "string",
              "description": "An address to print as a code, in the designs that place one."
            },
            "dateOfBirth": {
              "type": "string",
              "description": "A Lebenslauf carries one; a US résumé must not."
            },
            "nationality": {
              "type": "string"
            },
            "maritalStatus": {
              "type": "string"
            },
            "placeOfBirth": {
              "type": "string"
            }
          },
          "additionalProperties": false,
          "required": [
            "name"
          ]
        },
        "link": {
          "description": "An address. A bare string prints as the address shortened; an object names the label.",
          "oneOf": [
            {
              "type": "string"
            },
            {
              "type": "object",
              "properties": {
                "url": {
                  "type": "string"
                },
                "label": {
                  "type": "string"
                }
              },
              "additionalProperties": false,
              "required": [
                "url"
              ]
            }
          ]
        },
        "themeSpec": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "typeface": {
              "description": "A bundled family by name, or a family of your own by its files.",
              "oneOf": [
                {
                  "type": "string",
                  "enum": [
                    "inter",
                    "sans",
                    "sourceSerif",
                    "serif"
                  ]
                },
                {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "name"
                  ],
                  "properties": {
                    "name": {
                      "type": "string",
                      "description": "For diagnostics."
                    },
                    "files": {
                      "type": "array",
                      "items": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "path"
                        ],
                        "properties": {
                          "path": {
                            "type": "string",
                            "description": "A static TrueType file, relative to the file that names it."
                          },
                          "weight": {
                            "type": "integer",
                            "minimum": 100,
                            "maximum": 900,
                            "description": "400 when absent."
                          },
                          "italic": {
                            "type": "boolean",
                            "description": "false when absent."
                          }
                        }
                      }
                    },
                    "bundled": {
                      "type": [
                        "string",
                        "null"
                      ]
                    }
                  }
                }
              ]
            },
            "accent": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Brand colour as hex, such as #1F3A5F."
            },
            "pageSize": {
              "type": "string",
              "enum": [
                "A4",
                "A5",
                "Letter",
                "Legal"
              ],
              "description": "Matched without regard to case."
            },
            "density": {
              "type": "string",
              "enum": [
                "relaxed",
                "normal",
                "compact"
              ]
            },
            "justified": {
              "type": "boolean",
              "description": "Whether body prose is set flush to both edges."
            },
            "scheme": {
              "type": "string",
              "enum": [
                "light",
                "dark"
              ],
              "description": "Résumés, letters and cards."
            },
            "tint": {
              "type": "string",
              "pattern": "^#?([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$",
              "description": "Hex; the page painted this. Résumés, letters and cards."
            },
            "logo": {
              "type": "string",
              "description": "A PNG or JPEG for the designs with a place for one, relative to the file that names it. Markdown documents."
            }
          },
          "description": "The theme (the shape swift-document-theme defines, shared with press), laid over --theme; --var beats it. Paths are relative to this file."
        }
      }
    }

    """##

    static let cardBlueprint = ##"""
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "title": "Card design",
      "description": "A card design written as data: two sides, a fill each, and an ordered list of what sits on them.",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "name": {
          "type": "string"
        },
        "front": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "fill": {
              "description": "A named colour that follows the theme, or hex.",
              "anyOf": [
                {
                  "type": "string",
                  "enum": [
                    "ink",
                    "muted",
                    "accent",
                    "hairline",
                    "wash",
                    "page",
                    "rail",
                    "inverse",
                    "dark",
                    "darkest"
                  ]
                },
                {
                  "type": "string",
                  "pattern": "^#[0-9A-Fa-f]{6}$"
                }
              ]
            },
            "align": {
              "type": "string",
              "enum": [
                "left",
                "centre",
                "right"
              ]
            },
            "anchor": {
              "type": "string",
              "enum": [
                "top",
                "middle",
                "bottom"
              ]
            },
            "padding": {
              "type": "number",
              "description": "Kept from every trimmed edge, in points."
            },
            "content": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": [
                  "name",
                  "title",
                  "organisation",
                  "contacts",
                  "code",
                  "tagline",
                  "portrait",
                  "rule",
                  "space"
                ]
              },
              "description": "What is on the side, in the order it is drawn down it."
            }
          }
        },
        "back": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "fill": {
              "description": "A named colour that follows the theme, or hex.",
              "anyOf": [
                {
                  "type": "string",
                  "enum": [
                    "ink",
                    "muted",
                    "accent",
                    "hairline",
                    "wash",
                    "page",
                    "rail",
                    "inverse",
                    "dark",
                    "darkest"
                  ]
                },
                {
                  "type": "string",
                  "pattern": "^#[0-9A-Fa-f]{6}$"
                }
              ]
            },
            "align": {
              "type": "string",
              "enum": [
                "left",
                "centre",
                "right"
              ]
            },
            "anchor": {
              "type": "string",
              "enum": [
                "top",
                "middle",
                "bottom"
              ]
            },
            "padding": {
              "type": "number",
              "description": "Kept from every trimmed edge, in points."
            },
            "content": {
              "type": "array",
              "items": {
                "type": "string",
                "enum": [
                  "name",
                  "title",
                  "organisation",
                  "contacts",
                  "code",
                  "tagline",
                  "portrait",
                  "rule",
                  "space"
                ]
              },
              "description": "What is on the side, in the order it is drawn down it."
            }
          }
        },
        "size": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "width",
            "height"
          ],
          "properties": {
            "width": {
              "type": "number"
            },
            "height": {
              "type": "number"
            }
          },
          "description": "The trimmed size in points. 85 × 55 mm is 240.94 × 155.91."
        },
        "type": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "nameSize": {
              "type": "number"
            },
            "nameWeight": {
              "type": "string",
              "enum": [
                "regular",
                "semibold"
              ]
            },
            "uppercase": {
              "type": "boolean"
            },
            "tracking": {
              "type": "number"
            },
            "titleSize": {
              "type": "number"
            },
            "titleColour": {
              "description": "A named colour that follows the theme, or hex.",
              "anyOf": [
                {
                  "type": "string",
                  "enum": [
                    "ink",
                    "muted",
                    "accent",
                    "hairline",
                    "wash",
                    "page",
                    "rail",
                    "inverse",
                    "dark",
                    "darkest"
                  ]
                },
                {
                  "type": "string",
                  "pattern": "^#[0-9A-Fa-f]{6}$"
                }
              ]
            },
            "bodySize": {
              "type": "number"
            },
            "codeSize": {
              "type": "number",
              "description": "The code's side in points. Below 30 it fails on a printed card."
            }
          }
        },
        "photo": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "diameter": {
              "type": "number"
            },
            "align": {
              "type": "string",
              "enum": [
                "left",
                "centre",
                "right"
              ],
              "description": "left or right stands beside the words; centre stacks above them."
            }
          }
        },
        "pairsWith": {
          "type": "string",
          "description": "The résumé design this was drawn to sit beside."
        },
        "typeface": {
          "type": "string",
          "enum": [
            "sans",
            "serif"
          ]
        }
      }
    }

    """##

}
