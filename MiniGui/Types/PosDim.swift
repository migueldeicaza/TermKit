//
//  PosDim.swift
//  MiniGui
//
//  Created by Miguel de Icaza on 4/5/19.
//  Copyright © 2019 Miguel de Icaza. All rights reserved.
//

import Foundation


public class Pos {
    func Anchor (_ width : Int) -> Int { return 0 }
    
    class PosFactor : Pos {
        var factor : Float
        
        init (factor : Float)
        {
            self.factor = factor
        }
        
        override func Anchor(_ width: Int) -> Int {
            return Int (Float(width) * factor);
        }
    }
    
    public static func Percent (n : Float) throws -> Pos
    {
        if (n < 0 || n > 100){
            throw SizeError ()
        }
        return PosFactor (factor: n)
    }
    
    class PosAnchorEnd : Pos {
        var n : Int
        
        init (_ n : Int)
        {
            self.n = n
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return width - n
        }
    }
    
    static var emptyAnchorEnd = PosAnchorEnd (0)
    
    public static func AnchorEnd (margin : Int = 0) -> Pos
    {
        let actual = margin < 0 ? 0 : margin
        if actual == 0 {
            return emptyAnchorEnd
        }
        return PosAnchorEnd (margin)
    }
    
    class PosCenter : Pos {
        override func Anchor (_ width : Int) -> Int
        {
            return width / 2
        }
    }
    
    static var center = PosCenter ()
    
    public static func Center () -> Pos
    {
        return center
    }
    
    class PosAbsolute : Pos {
        var n : Int
        
        init (_ n : Int)
        {
            self.n = n
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            return n
        }
    }
    
    public static func Pos (n : Int) -> Pos
    {
        return PosAbsolute (n)
    }
    
    class PosCombine : Pos {
        var left, right : Pos
        var add : Bool
        
        init (left : Pos, right : Pos, add : Bool)
        {
            self.left = left
            self.right = right
            self.add = add
        }
        
        override func Anchor (_ width : Int) -> Int
        {
            let la = left.Anchor (width)
            let ra = right.Anchor (width)
            return add ? la + ra : la - ra
        }
    }
    
    public static func + (lhs:Pos, rhs: Pos) -> Pos
    {
        return PosCombine (left: lhs, right: rhs, add: true)
    }

    public static func - (lhs:Pos, rhs: Pos) -> Pos
    {
        return PosCombine (left: lhs, right: rhs, add: false)
    }
    
    enum Side {
        case X
        case Y
        case Right
        case Bottom
    }
    
    class PosView : Pos {
        var target : View
        var side : Side
        
        init (_ view : View, side : Side)
        {
            self.target = view
            self.side = side
        }
       
        override func Anchor (_ width : Int) -> Int
        {
            switch (side){
            case .X:
                return target.frame.X
            case .Y:
                return target.frame.Y
            case .Right:
                return target.frame.Right
            case .Bottom:
                return target.frame.Bottom
            }
        }
    }
    
    public static func Left (of view : View) -> Pos
    {
        return PosView (view, side: .X)
    }

    public static func X (of view : View) -> Pos
    {
        return PosView (view, side: .X)
    }

    public static func Top (of view : View) -> Pos
    {
        return PosView (view, side: .Y)
    }
    
    public static func Y (of view : View) -> Pos
    {
        return PosView (view, side: .Y)
    }

    public static func Right (of view : View) -> Pos
    {
        return PosView (view, side: .Right)
    }
    
    public static func Bottom (of view : View) -> Pos
    {
        return PosView (view, side: .Bottom)
    }
}
