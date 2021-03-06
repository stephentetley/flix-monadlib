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



///
/// A type class for monads.
///
pub lawless class Monad[m :# Type -> Type] with Applicative[m] {

    pub def bind(x: m[a], k: a -> m[b]): m[b]

}


instance Monad[List] {
    pub def bind(f: List[a], k: a -> List[b]): List[b] = List.flatMap(k, f)
}

instance Monad[Option] {
    pub def bind(f: Option[a], k: a -> Option[b]): Option[b] = Option.flatMap(k, f)
}


namespace Monad {
    
    use Applicative.{return};
    use Alternative.{alt, zero};
    use Monad.{bind};

    pub def >>=[a, b, m :# Type -> Type : Monad](x: m[a], k: a -> m[b]): m[b] =
        bind(x, k)

    pub def =<<[a, b, m :# Type -> Type : Monad](k: a -> m[b], x: m[a]): m[b] =
        bind(x, k)


    pub def kleisliLeft[a, b, c, m :# Type -> Type : Monad](f1: a -> m[b], f2: b -> m[c]): a -> m[c] = x ->
        bind(f1(x), x1 -> f2(x1))

    pub def kleisliRight[a, b, c, m :# Type -> Type : Monad](f1: b -> m[c], f2: a -> m[b]): a -> m[c] = x -> 
        bind(f2(x), x1 -> f1(x1))      
    
    /// Alias for `kleisliLeft`
    pub def >=>[a, b, c, m :# Type -> Type : Monad](f1: a -> m[b], f2: b -> m[c]): a -> m[c] = x ->
        kleisliLeft(f1, f2, x)

    /// Alias for `kleisliRight`
    pub def <=<[a, b, c, m :# Type -> Type : Monad](f1: b -> m[c], f2: a -> m[b]): a -> m[c] = x -> 
        kleisliRight(f1, f2, x)

    pub def whenTrueM[a, m :# Type -> Type : Monad](test: m[Bool], ma: m[a]): m[Option[a]] = 
        bind(test, x -> Applicative.whenTrue(x, ma))

    pub def whenFalseM[a, m :# Type -> Type : Monad](test: m[Bool], ma: m[a]): m[Option[a]] = 
        bind(test, x -> Applicative.whenFalse(x, ma))

    pub def mfilter[a, m :# Type -> Type : Monad : Alternative](f: a -> Bool, mx: m[a]): m[a] = 
        bind(mx, x -> if (f(x)) return(x) else zero())

    pub def foldLeftM[a, b, m :# Type -> Type : Monad](f: (b, a) -> m[b], s: b, xs: List[a]): m[b] = 
        foldLeftMHelper(f, return(s), xs)

    def foldLeftMHelper[a, b, m :# Type -> Type : Monad](f: (b, a) -> m[b], s: m[b], xs: List[a]): m[b] = match xs {
        case Nil => s
        case x :: rs => foldLeftMHelper(f, bind(s, s1 -> f(s1, x)), rs)
    }

    pub def foldRightM[a, b, m :# Type -> Type : Monad](f: (a, b) -> m[b], s: b, xs: List[a]): m[b] = 
        foldRightMHelper(f, return(s), xs, ms -> ms)

    ///
    /// Helper function for `foldRightM`.
    ///
    def foldRightMHelper[a, b, m :# Type -> Type : Monad](f: (a, b) -> m[b], s: m[b], xs: List[a], k: m[b] -> m[b]): m[b] = match xs {
        case Nil => k(s)
        case x :: rs => foldRightMHelper(f, s, rs, ms -> k(bind(ms, s1 -> f(x, s1))))
    }



    /// Chains

    pub def chainl[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) -> a], x: a): m[a] = 
        alt(chainl1(p,op), return(x))

    pub def chainl1[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) -> a]): m[a] = 
        bind(p, v1 -> chainl1Helper(p, op, v1))
        
    def chainl1Helper[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) -> a], x: a): m[a] = 
        alt(bind(op, f -> bind(p, v1 -> chainl1Helper(p, op, f(x, v1))))
            , return(x))

    pub def chainr1[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) -> a]): m[a] = 
        bind(p, v1 -> chainr1Helper(p, op, v1))
    
    def chainr1Helper[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) -> a], x: a): m[a] = 
        alt(chainr1Step(p, op, x), return(x))

    def chainr1Step[a, m :# Type -> Type : Monad : Alternative](p: m[a], op: m[(a, a) ->a], x: a): m[a] = 
        bind(op, f -> 
            bind(bind(p, v1 -> chainr1Helper(p, op, v1)), y -> 
                bind(chainr1Helper(p,op, f(x,y)), ans -> return(ans))))

}