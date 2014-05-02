(* sepcomp imports *)

Require Import linking.sepcomp. Import SepComp. 
Require Import sepcomp.arguments.

Require Import linking.pos.
Require Import linking.core_semantics_lemmas.
Require Import linking.compcert_linking.
Require Import linking.rc_semantics.
Require Import linking.rc_semantics_lemmas.
Require Import linking.linking_spec.

(* ssreflect *)

Require Import ssreflect ssrbool ssrfun seq eqtype fintype.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Require Import sepcomp.nucular_semantics.
Require Import compcert.common.Values.   

Import Wholeprog_simulation.
Import SM_simulation.
Import Linker. 
Import Modsem.

Module ContextEquiv (LS : LINKING_SIMULATION).                  
                                                                       
Import LS.                                                             
                                                                       
Lemma pos_incr' (p : pos) : (0 < (p+1))%nat.                           
Proof. omega. Qed.                                                     
                                                                       
Definition pos_incr (p : pos) := mkPos (pos_incr' p).                  

Section ContextEquiv.

Variable (N0 : pos) (sems_S0 sems_T0 : 'I_N0 -> Modsem.t).
Variable nucular_T0 : forall ix : 'I_N0, Nuke_sem.t (sems_T0 ix).(sem).

Variable plt0 : ident -> option 'I_N0.
Variable sims0 : forall ix : 'I_N0,                                          
                 let s := sems_S0 ix in                                              
                 let t := sems_T0 ix in                                              
                 SM_simulation_inject s.(sem) t.(sem) s.(ge) t.(ge).

Variable ge_top : ge_ty.                                                     

Variable domeq_S0 : forall ix : 'I_N0, genvs_domain_eq ge_top (sems_S0 ix).(ge).
Variable domeq_T0 : forall ix : 'I_N0, genvs_domain_eq ge_top (sems_T0 ix).(ge). 

Variable C : Modsem.t.   
Variable sim_C : SM_simulation_inject C.(sem) C.(sem) C.(ge) C.(ge).
Variable domeq_C : genvs_domain_eq ge_top C.(ge).
Variable nuke_C : Nuke_sem.t (sem C).

Let N := pos_incr N0.

Lemma lt_ssrnatlt n m : lt n m -> ssrnat.leq (S n) m.
Proof. by move=> H; apply/ssrnat.ltP. Qed.

Definition extend_sems (f : 'I_N0 -> Modsem.t) (ix : 'I_N) : Modsem.t :=
  match lt_dec ix N0 with
    | left pf => let ix' : 'I_N0 := Ordinal (lt_ssrnatlt pf) in f ix'
    | right _ => C
  end.

Let sems_S := extend_sems sems_S0.

Let sems_T := extend_sems sems_T0.

Lemma sims (ix : 'I_N) :
  let s := sems_S ix in
  let t := sems_T ix in
  SM_simulation_inject (sem s) (sem t) (ge s) (ge t).
Proof.
rewrite /sems_S /sems_T /extend_sems; case e: (lt_dec ix N0)=> [pf|//].
by apply: (sims0 (Ordinal (lt_ssrnatlt pf))).
Qed.

Let sems_S' (ix : 'I_N) :=        
  Modsem.mk (sems_S ix).(ge) (RC.effsem (sems_S ix).(sem)).

Lemma leq_N0_N : ssrnat.leq N0 N.
Proof. by rewrite /N /= plus_comm. Qed.

Lemma leq_SN0_N : ssrnat.leq (S N0) N.
Proof. by rewrite /N /= plus_comm. Qed.

Let plt (id : ident) := 
  match plt0 id with
    | None => Some (Ordinal leq_SN0_N)
    | Some ix => Some (widen_ord leq_N0_N ix)
  end.

Let linker_S := effsem N sems_S' plt.

Let linker_T := effsem N sems_T plt.

Lemma nucular_T (ix : 'I_N) : Nuke_sem.t (sem (sems_T ix)).
Proof.
rewrite /sems_T /extend_sems; case e: (lt_dec ix N0)=> [//|].
by apply: nuke_C.
Qed.

Lemma sm_inject (ix : 'I_N) :
 let s := sems_S ix in
 let t0 := sems_T ix in
 SM_simulation_inject (sem s) (sem t0) (ge s) (ge t0).
Proof.
rewrite /= /sems_S /sems_T /extend_sems; case e: (lt_dec _ _)=> [//|].
by apply: sim_C.
Qed.

Lemma genvs_domeq_S (ix : 'I_N) : genvs_domain_eq ge_top (ge (sems_S ix)).
Proof. 
rewrite /sems_S /extend_sems; case e: (lt_dec _ _)=> [//|].
by apply: domeq_C.
Qed.

Lemma genvs_domeq_T (ix : 'I_N) : genvs_domain_eq ge_top (ge (sems_T ix)).
Proof. 
rewrite /sems_T /extend_sems; case e: (lt_dec _ _)=> [//|].
by apply: domeq_C.
Qed.

Lemma ContextEquiv (main : val) :
  Wholeprog_simulation linker_S linker_T ge_top ge_top main.
Proof.
apply: link=> //; first by apply: nucular_T.
by apply: sm_inject.
by apply: genvs_domeq_S.
by apply: genvs_domeq_T.
Qed.




  

