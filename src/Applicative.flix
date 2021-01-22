/*
 * Copyright 2021 Stephen Tetley
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


class Applicative[m :# Type -> Type] extends Functor[m] {
    
    pub def point(x: a): m[a] 

    pub def ap(f: m[a -> b & ef] , x: m[a]): m[b] & ef

}


instance Applicative[List] {

    def point(x: a): List[a] = x :: Nil
    
    def ap(f: List[a -> b & ef], x: List[a]): List[b] & ef = List.zipWith((f1, a) -> f1(a), f, x)
}

instance Applicative[Option] {

    def point(x: a): Option[a] = Some(x)
    
    def ap(f: Option[a -> b & ef], x: Option[a]): Option[b] & ef = 
        match f { 
            case None => None
            case Some(f1) => Option.map(f1, x)
        }
}


namespace Applicative {

    // Haskell's <$>
    pub def <&>[a, b, ef, m :# Type -> Type : Functor](f: a -> b & ef, mx: m[a]): m[b] & ef =
        Functor.map(f, mx)

    // Haskell's ap <*>
    pub def <*>[a, b, ef, m :# Type -> Type : Applicative](f: m[a -> b & ef], mx: m[a]): m[b] & ef =
        Applicative.ap(f, mx)


    pub def seqLeft[a, b, m :# Type -> Type : Applicative](mx: m[a], my: m[b]): m[a] = 
        (((x1, _) -> x1) <&> mx) <*> my

    pub def seqRight[a, b, m :# Type -> Type : Applicative](mx: m[a], my: m[b]): m[b] = 
        (((_, x2) -> x2) <&> mx) <*> my


    /// Alias for `seqLeft`
    pub def <*[a, b, m :# Type -> Type : Applicative](mx: m[a], my: m[b]): m[a] = seqLeft(mx, my)

    /// Alias for `seqRight`
    pub def *>[a, b, m :# Type -> Type : Applicative](mx: m[a], my: m[b]): m[b] = seqRight(mx, my)



    pub def liftA2[t1, t2, t3, ef, m :# Type -> Type : Applicative](f: (t1, t2) -> t3 & ef, a1: m[t1], a2: m[t2]): m[t3] & ef = 
        (((x1, x2) -> f(x1, x2)) <&> a1) <*> a2

    pub def liftA3[t1, t2, t3, t4, ef, m :# Type -> Type : Applicative](f: (t1, t2, t3) -> t4 & ef, a1: m[t1], a2: m[t2], a3: m[t3]): m[t4] & ef = 
        liftA2(f, a1, a2) <*> a3

    pub def liftA4[t1, t2, t3, t4, t5, ef, m :# Type -> Type : Applicative](f: (t1, t2, t3, t4) -> t5 & ef, a1: m[t1], a2: m[t2], a3: m[t3], a4: m[t4]): m[t5] & ef = 
        liftA3(f, a1, a2, a3) <*> a4

    pub def liftA5[t1, t2, t3, t4, t5, t6, ef, m :# Type -> Type : Applicative](f: (t1, t2, t3, t4, t5) -> t6 & ef, a1: m[t1], a2: m[t2], a3: m[t3], a4: m[t4], a5: m[t5]): m[t6] & ef = 
        liftA4(f, a1, a2, a3, a4) <*> a5

    pub def liftA6[t1, t2, t3, t4, t5, t6, t7, ef, m :# Type -> Type : Applicative](f: (t1, t2, t3, t4, t5, t6) -> t7 & ef, a1: m[t1], a2: m[t2], a3: m[t3], a4: m[t4], a5: m[t5], a6: m[t6]): m[t7] & ef = 
        liftA5(f, a1, a2, a3, a4, a5) <*> a6

}