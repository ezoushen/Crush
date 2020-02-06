//
//  Property+TypeStringConvertible.swift
//  Crush
//
//  Created by 沈昱佐 on 2020/2/5.
//

import Foundation

extension Optional.Relation {
    public struct One {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Optional.Relation.OneToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Optional.Relation.OneToMany"
            }
        }
    }
    
    public struct Many {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Optional.Relation.ManyToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Required.Relation.ManyToMany"
            }
        }
    }
}

extension Required.Relation {
    public struct One {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Required.Relation.OneToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Required.Relation.OneToMany"
            }
        }
    }
    
    public struct Many {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Required.Relation.ManyToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Required.Relation.ManyToMany"
            }
        }
    }
}

extension Transient.Optional.Relation {
    public struct One {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Optional.Relation.OneToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Optional.Relation.OneToMany"
            }
        }
    }
    
    public struct Many {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Optional.Relation.ManyToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Required.Relation.ManyToMany"
            }
        }
    }
}

extension Transient.Required.Relation {
    public struct One {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Required.Relation.OneToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Required.Relation.OneToMany"
            }
        }
    }
    
    public struct Many {
        public struct ToOne: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Required.Relation.ManyToOne"
            }
        }
        
        public struct ToMany: TypeStringConvertible {
            public static var typedef: String {
                return "@Transient.Required.Relation.ManyToMany"
            }
        }
    }
}
