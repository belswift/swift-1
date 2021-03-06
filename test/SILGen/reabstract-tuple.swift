// RUN: %target-swift-frontend -enable-sil-ownership -emit-silgen -verify %s | %FileCheck %s

// SR-3090:

class Box<T> {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}

// CHECK: sil @_T04main7testBoxyyF : $@convention(thin) () -> () {
// CHECK: bb0:
// CHECK:   // function_ref Box.__allocating_init(_:)
// CHECK:   [[INIT_F:%.*]] = function_ref @_T04main3BoxCACyxGxcfC : $@convention(method) <τ_0_0> (@in τ_0_0, @thick Box<τ_0_0>.Type) -> @owned Box<τ_0_0> // user: %26
// CHECK:   // function_ref closure #1 in testBox()
// CHECK:   [[CLOSURE:%.*]] = function_ref @_T04main7testBoxyyFyycfU_ : $@convention(thin) () -> ()
// CHECK:   [[THICK:%.*]] = thin_to_thick_function [[CLOSURE]] : $@convention(thin) () -> () to $@callee_owned () -> ()
// CHECK:   [[TUPLEA:%.*]] = tuple (%{{.*}} : $Int, [[THICK]] : $@callee_owned () -> ())
// CHECK:   [[BORROWA:%.*]] = begin_borrow [[TUPLEA]] : $(Int, @callee_owned () -> ())
// CHECK:   [[ELTA_0:%.*]] = tuple_extract [[BORROWA]] : $(Int, @callee_owned () -> ()), 0
// CHECK:   [[ELTA_1:%.*]] = tuple_extract [[BORROWA]] : $(Int, @callee_owned () -> ()), 1
// CHECK:   [[COPYA_1:%.*]] = copy_value [[ELTA_1]] : $@callee_owned () -> () 
// CHECK:   end_borrow [[BORROWA]] from %{{.*}} : $(Int, @callee_owned () -> ()), $(Int, @callee_owned () -> ())
// CHECK:   [[THUNK1:%.*]] = function_ref @_T0Ix_ytytIxir_TR : $@convention(thin) (@in (), @owned @callee_owned () -> ()) -> @out ()
// CHECK:   [[PA:%.*]] = partial_apply [[THUNK1]]([[COPYA_1]]) : $@convention(thin) (@in (), @owned @callee_owned () -> ()) -> @out ()
// CHECK:   [[TUPLEB:%.*]] = tuple ([[ELTA_0]] : $Int, [[PA]] : $@callee_owned (@in ()) -> @out ())
// CHECK:   [[BORROWB:%.*]] = begin_borrow [[TUPLEB]] : $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   [[TUPLEB_0:%.*]] = tuple_extract [[BORROWB]] : $(Int, @callee_owned (@in ()) -> @out ()), 0
// CHECK:   [[TUPLEB_1:%.*]] = tuple_extract [[BORROWB]] : $(Int, @callee_owned (@in ()) -> @out ()), 1
// CHECK:   [[COPYB_1:%.*]] = copy_value [[TUPLEB_1]] : $@callee_owned (@in ()) -> @out ()
// CHECK:   [[CALL:%.*]] = apply [[INIT_F]]<(Int, () -> ())>(%{{.*}}, %{{.*}}) : $@convention(method) <τ_0_0> (@in τ_0_0, @thick Box<τ_0_0>.Type) -> @owned Box<τ_0_0>
// CHECK:   end_borrow [[BORROWB]] from %{{.*}} : $(Int, @callee_owned (@in ()) -> @out ()), $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   destroy_value [[TUPLEB]] : $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   destroy_value [[TUPLEA]] : $(Int, @callee_owned () -> ())
// CHECK:   [[BORROW_CALL:%.*]] = begin_borrow [[CALL]] : $Box<(Int, () -> ())> 
// CHECK:   [[REF:%.*]] = ref_element_addr [[BORROW_CALL]] : $Box<(Int, () -> ())>, #Box.value
// CHECK:   [[READ:%.*]] = begin_access [read] [dynamic] [[REF]] : $*(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   [[TUPLEC:%.*]] = load [copy] [[READ]] : $*(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   [[BORROW_TUPLEC:%.*]] = begin_borrow [[TUPLEC]] : $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   [[TUPLEC_0:%.*]] = tuple_extract [[BORROW_TUPLEC]] : $(Int, @callee_owned (@in ()) -> @out ()), 0
// CHECK:   [[TUPLEC_1:%.*]] = tuple_extract [[BORROW_TUPLEC]] : $(Int, @callee_owned (@in ()) -> @out ()), 1
// CHECK:   [[COPYC_1:%.*]] = copy_value [[TUPLEC_1]] : $@callee_owned (@in ()) -> @out ()
// CHECK:   [[THUNK2:%.*]] = function_ref @_T0ytytIxir_Ix_TR : $@convention(thin) (@owned @callee_owned (@in ()) -> @out ()) -> ()
// CHECK:   [[PA2:%.*]] = partial_apply [[THUNK2]]([[COPYC_1]]) : $@convention(thin) (@owned @callee_owned (@in ()) -> @out ()) -> ()
// CHECK:   end_access [[READ]] : $*(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   destroy_value [[PA2]] : $@callee_owned () -> ()    
// CHECK:   end_borrow [[BORROW_TUPLEC]] from %{{.*}} : $(Int, @callee_owned (@in ()) -> @out ()), $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   destroy_value [[TUPLEC]] : $(Int, @callee_owned (@in ()) -> @out ())
// CHECK:   end_borrow [[BORROW_CALL]] from %{{.*}} : $Box<(Int, () -> ())>, $Box<(Int, () -> ())>
// CHECK-LABEL: } // end sil function '_T04main7testBoxyyF'
public func testBox() {
  let box = Box((22, { () in }))
  let foo = box.value.0
  print(foo)
}


// Another crash -- re-abstracting function type inside optional in tuple
// in-place

func g<T>() -> (Int, T)? { }

func f<T>(t: T) {
  let _: (Int, ((T) -> (), T))? = g()
}
