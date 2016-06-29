Require Import RamifyCoq.lib.List_ext.
Require Import RndHoare.sigma_algebra.
Require Import RndHoare.measurable_function.
Require Import RndHoare.regular_conditional_prob.
Require Import RndHoare.random_oracle.
Require Import RndHoare.random_history_order.
Require Import RndHoare.random_history_conflict.
Require Import RndHoare.history_anti_chain.
Require Import RndHoare.random_variable.
Require Import RndHoare.meta_state.
Require Import RndHoare.pstate_stream_lemmas.
Require Import RndHoare.pstate_stream_limit.
Require Import Coq.Classes.Equivalence.
Require Import Coq.Classes.Morphisms.

Section CutStream.

Context {ora: RandomOracle} {SFo: SigmaAlgebraFamily RandomHistory} {HBSFo: HistoryBasedSigF ora} {state: Type} {state_sigma: SigmaAlgebra state}.

Variable (filter: nat -> measurable_set (MetaState state)).

Variables (Omegas: RandomVarDomainStream) (l: ProgStateStream Omegas state) (dir: ConvergeDir l).

Inductive local_step_label: nat -> RandomHistory -> nat -> nat -> Prop :=
  | label_0: forall h, dir 0 h -> local_step_label 0 h 0 0
  | label_m: forall n h' h m r, dir (S n) h -> local_step_label n h' m r -> prefix_history h' h -> 
               (forall s, l (S n) h s -> ~ filter m s) -> local_step_label (S n) h m (S r)
  | label_Sm: forall n h' h m r, dir (S n) h -> local_step_label n h' m r -> prefix_history h' h -> 
               (forall s, l (S n) h s -> filter m s) -> local_step_label (S n) h (S m) 0
.

Inductive status: Type :=
  | ActiveBranch: nat -> status
  | SingleStreamEnd: nat -> status
  | FullStreamEnd: status.

Inductive local_step_rev: forall (m r: nat) (h: RandomHistory) (k: status), Prop :=
  | rev_ActiveBranch:
      forall m r h n,
        local_step_label n h m r ->
        local_step_rev m r h (ActiveBranch n)
  | rev_SingleStreamEnd:
      forall m r h n,
        (forall n' h', prefix_history h' h -> ~ local_step_label n' h' m r) ->
        local_step_label n h (S m) 0 ->
        local_step_rev m r h (SingleStreamEnd n)
  | rev_FullStreamEnd:
      forall m r h,
        (forall n' h', prefix_history h' h -> ~ local_step_label n' h' m r) ->
        (forall n' h', prefix_history h' h -> ~ local_step_label n' h' (S m) 0) ->
        (limit_domain Omegas) h ->
        local_step_rev m r h FullStreamEnd
.

Inductive raw_sdomains: forall (m r: nat) (h: RandomHistory), Prop :=
  | dom_ActiveBranch:
      forall m r h n, local_step_rev m r h (ActiveBranch n) -> raw_sdomains m r h
  | dom_SingleStreamEnd:
      forall m r h n, local_step_rev m r h (SingleStreamEnd n) -> raw_sdomains m r h
  | dom_FullStreamEnd:
      forall m r h, local_step_rev m r h FullStreamEnd -> raw_sdomains m r h
.

Inductive raw_sdir: forall (m r: nat) (h: RandomHistory), Prop :=
  | dir_ActiveBranch:
      forall m r h n, local_step_rev m r h (ActiveBranch n) -> raw_sdir m r h
.

Inductive raw_sstate: forall (m r: nat) (h: RandomHistory) (s: MetaState state), Prop :=
  | state_ActiveBranch:
      forall m r h n s, local_step_rev m r h (ActiveBranch n) -> l n h s -> raw_sstate m r h s
  | state_SingleStreamEnd:
      forall m r h n s, local_step_rev m r h (SingleStreamEnd n) -> l n h s -> raw_sstate m r h s
  | state_FullStreamEnd:
      forall m r h s, local_step_rev m r h FullStreamEnd -> (limit l dir) h s -> raw_sstate m r h s
.

Definition raw_fdomains (m: nat) (h: RandomHistory): Prop := raw_sdomains m 0 h.

Definition raw_fdir (m: nat) (h: RandomHistory): Prop := raw_sdir m 0 h.

Definition raw_fstate (m: nat) (h: RandomHistory) (s: MetaState state): Prop := raw_sstate m 0 h s.

Lemma labeled_in_dir: forall n h m r,
  local_step_label n h m r ->
  dir n h.
Proof.
  intros.
  inversion H; auto.
Qed.

Lemma two_labeled_prefix_eq: forall n h h1 h2 m1 r1 m2 r2,
  local_step_label n h1 m1 r1 ->
  local_step_label n h2 m2 r2 ->
  prefix_history h1 h ->
  prefix_history h2 h ->
  h1 = h2.
Proof.
  intros.
  pose proof labeled_in_dir _ _ _ _ H.
  pose proof labeled_in_dir _ _ _ _ H0.
  apply (anti_chain_not_comparable' (dir n)); auto.
  eapply prefix_history_comparable; eauto.
Qed.

Lemma local_step_label_functionality: forall n h m1 r1 m2 r2,
  local_step_label n h m1 r1 ->
  local_step_label n h m2 r2 ->
  m1 = m2 /\ r1 = r2.
Proof.
  intros.
  revert h m1 m2 r1 r2 H H0; induction n; intros.
  + inversion H; inversion H0; subst.
    auto.
  + inversion H; inversion H0; subst.
    - assert (h' = h'0) by (eapply (two_labeled_prefix_eq n h); eauto).
      subst h'0.
      specialize (IHn h' m1 m2 r r0 H3 H11).
      destruct IHn; subst; auto.
    - assert (h' = h'0) by (eapply (two_labeled_prefix_eq n h); eauto).
      subst h'0.
      specialize (IHn h' _ _ _ _ H3 H11).
      destruct IHn; subst; exfalso.
      pose proof PrFamily.rf_complete _ _ (l (S n)) h as [s ?]; [eapply MeasurableSubset_in_domain; eauto |].
      specialize (H13 _ H1).
      specialize (H5 _ H1).
      auto.
    - assert (h' = h'0) by (eapply (two_labeled_prefix_eq n h); eauto).
      subst h'0.
      specialize (IHn h' _ _ _ _ H3 H11).
      destruct IHn; subst; exfalso.
      pose proof PrFamily.rf_complete _ _ (l (S n)) h as [s ?]; [eapply MeasurableSubset_in_domain; eauto |].
      specialize (H13 _ H1).
      specialize (H5 _ H1).
      auto.
    - assert (h' = h'0) by (eapply (two_labeled_prefix_eq n h); eauto).
      subst h'0.
      specialize (IHn h' _ _ _ _ H3 H11).
      destruct IHn; subst; auto.
Qed.

Lemma local_step_label_strict_order_derives: forall n1 n2 h1 h2 m1 r1 m2 r2,
  n1 < n2 ->
  prefix_history h1 h2 ->
  local_step_label n1 h1 m1 r1 ->
  local_step_label n2 h2 m2 r2 ->
  m1 < m2 \/ m1 = m2 /\ r1 < r2.
Proof.
  intros.
  remember (n2 - n1 - 1) as Delta.
  assert (n2 = Delta + (S n1)) by omega.
  subst n2; clear HeqDelta H.
  revert h2 m2 r2 H0 H2; induction Delta; intros.
  + simpl in H2.
    inversion H2; subst.
    - assert (h' = h1) by (eapply (two_labeled_prefix_eq n1 h2); eauto).
      subst h'.
      destruct (local_step_label_functionality _ _ _ _ _ _ H1 H4).
      subst; right; omega.
    - assert (h' = h1) by (eapply (two_labeled_prefix_eq n1 h2); eauto).
      subst h'.
      destruct (local_step_label_functionality _ _ _ _ _ _ H1 H4).
      subst; left; omega.
  + simpl in H2.
    inversion H2; subst.
    - assert (prefix_history h1 h').
      Focus 1. {
        apply (proj_in_anti_chain_unique (dir n1) _ _ h2); auto.
        + apply (ConvergeDir_mono dir n1 (Delta + S n1)); [omega |].
          eapply labeled_in_dir; eauto.
        + eapply labeled_in_dir; eauto.
      } Unfocus.
      specialize (IHDelta _ _ _ H H4).
      omega.
    - assert (prefix_history h1 h').
      Focus 1. {
        apply (proj_in_anti_chain_unique (dir n1) _ _ h2); auto.
        + apply (ConvergeDir_mono dir n1 (Delta + S n1)); [omega |].
          eapply labeled_in_dir; eauto.
        + eapply labeled_in_dir; eauto.
      } Unfocus.
      specialize (IHDelta _ _ _ H H4).
      omega.
Qed.

Lemma local_step_label_comparable_history_strict_order: forall n1 n2 h1 h2 m1 r1 m2 r2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_label n1 h1 m1 r1 ->
  local_step_label n2 h2 m2 r2 ->
  (prefix_history h1 h2 /\ n1 < n2 /\ (m1 < m2 \/ m1 = m2 /\ r1 < r2)) \/
  (h1 = h2 /\ n1 = n2 /\ m1 = m2 /\ r1 = r2) \/
  (prefix_history h2 h1 /\ n1 > n2 /\ (m1 > m2 \/ m1 = m2 /\ r1 > r2)).
Proof.
  intros.
  destruct H; destruct (lt_eq_lt_dec n1 n2) as [[?H | ?H] | ?H].
  + left.
    split; auto.
    pose proof local_step_label_strict_order_derives _ _ _ _ _ _ _ _ H2 H H0 H1.
    omega.
  + right; left.
    subst n2; rename n1 into n.
    pose proof labeled_in_dir _ _ _ _ H0.
    pose proof labeled_in_dir _ _ _ _ H1.
    pose proof anti_chain_not_comparable _ _ _ H2 H3 H.
    subst h2; rename h1 into h.
    pose proof local_step_label_functionality _ _ _ _ _ _ H0 H1.
    auto.
  + right; right.
    pose proof labeled_in_dir _ _ _ _ H0.
    pose proof labeled_in_dir _ _ _ _ H1.
    destruct (fun HH => ConvergeDir_mono dir n2 n1 HH h1 H3) as [h2' [? ?]]; [omega |].
    pose proof anti_chain_not_comparable _ _ _ H6 H4 (prefix_history_trans _ _ _ H5 H).
    subst h2'.
    pose proof local_step_label_strict_order_derives _ _ _ _ _ _ _ _ H2 H5 H1 H0.
    split; auto; omega.
  + left.
    pose proof labeled_in_dir _ _ _ _ H0.
    pose proof labeled_in_dir _ _ _ _ H1.
    destruct (fun HH => ConvergeDir_mono dir n1 n2 HH h2 H4) as [h1' [? ?]]; [omega |].
    pose proof anti_chain_not_comparable _ _ _ H6 H3 (prefix_history_trans _ _ _ H5 H).
    subst h1'.
    pose proof local_step_label_strict_order_derives _ _ _ _ _ _ _ _ H2 H5 H0 H1.
    split; auto; omega.
  + right; left.
    subst n2; rename n1 into n.
    pose proof labeled_in_dir _ _ _ _ H0.
    pose proof labeled_in_dir _ _ _ _ H1.
    pose proof anti_chain_not_comparable _ _ _ H3 H2 H.
    subst h2; rename h1 into h.
    pose proof local_step_label_functionality _ _ _ _ _ _ H0 H1.
    auto.
  + right; right.
    split; auto.
    pose proof local_step_label_strict_order_derives _ _ _ _ _ _ _ _ H2 H H1 H0.
    omega.
Qed.

Lemma local_step_label_strict_backward: forall n2 h2 m r1 r2,
  r1 < r2 ->
  local_step_label n2 h2 m r2 ->
  exists n1 h1,
  n1 < n2 /\ prefix_history h1 h2 /\ local_step_label n1 h1 m r1.
Proof.
  intros.
  remember (r2 - r1 - 1) as Delta.
  assert (r2 = Delta + S r1) by omega; subst r2.
  clear H HeqDelta.
  revert n2 h2 H0; induction Delta; intros.
  + inversion H0; subst.
    exists n, h'; split; [omega | split; auto].
  + inversion H0; subst.
    specialize (IHDelta _ _ H2).
    destruct IHDelta as [n1 [h1 [? [? ?]]]].
    exists n1, h1.
    split; [omega | split; [| auto]].
    eapply prefix_history_trans; eauto.
Qed.

Lemma local_step_label_backward: forall n2 h2 m r1 r2,
  r1 <= r2 ->
  local_step_label n2 h2 m r2 ->
  exists n1 h1,
  n1 <= n2 /\ prefix_history h1 h2 /\ local_step_label n1 h1 m r1.
Proof.
  intros.
  destruct (lt_dec r1 r2).
  + destruct (local_step_label_strict_backward n2 h2 m r1 r2 l0 H0) as [n1 [h1 [? [? ?]]]].
    exists n1, h1; split; [omega | auto].
  + exists n2, h2.
    assert (r1 = r2) by omega; subst r2.
    split; [omega | split; [apply prefix_history_refl | auto]].
Qed.
  
Lemma local_step_rev_strong_functionality_aux_AA: forall m r h1 h2 n1 n2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 (ActiveBranch n1) ->
  local_step_rev m r h2 (ActiveBranch n2) ->
  n1 = n2 /\ h1 = h2.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ H H6 H11) as [? | [? | ?]];
  [omega | tauto | omega].
Qed.

Lemma local_step_rev_strong_functionality_aux_AS: forall m r h1 h2 n1 n2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 (ActiveBranch n1) ->
  local_step_rev m r h2 (SingleStreamEnd n2) ->
  False.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ H H6 H12) as [? | [? | ?]];
  [| omega | omega].
  apply (H8 _ _ (proj1 H2) H6).
Qed.

Lemma local_step_rev_strong_functionality_aux_AF: forall m r h1 h2 n1,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 (ActiveBranch n1) ->
  local_step_rev m r h2 FullStreamEnd ->
  False.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  apply (future_anti_chain_comparable_choice (Omegas n1) (limit_domain Omegas)) in H.
  + apply (H7 _ _ H H6).
  + apply limit_domain_forward.
  + apply labeled_in_dir in H6.
    eapply MeasurableSubset_in_domain; eauto.
  + auto.
Qed.

Lemma local_step_rev_strong_functionality_aux_SS: forall m r h1 h2 n1 n2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 (SingleStreamEnd n1) ->
  local_step_rev m r h2 (SingleStreamEnd n2) ->
  n1 = n2 /\ h1 = h2.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ H H7 H13) as [? | [? | ?]];
  [omega | tauto | omega].
Qed.

Lemma local_step_rev_strong_functionality_aux_SF: forall m r h1 h2 n1,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 (SingleStreamEnd n1) ->
  local_step_rev m r h2 FullStreamEnd ->
  False.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  apply (future_anti_chain_comparable_choice (Omegas n1) (limit_domain Omegas)) in H.
  + apply (H9 _ _ H H7).
  + apply limit_domain_forward.
  + apply labeled_in_dir in H7.
    eapply MeasurableSubset_in_domain; eauto.
  + auto.
Qed.

Lemma local_step_rev_strong_functionality_aux_FF: forall m r h1 h2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 FullStreamEnd ->
  local_step_rev m r h2 FullStreamEnd ->
  h1 = h2.
Proof.
  intros.
  inversion H0; inversion H1; subst.
  clear - H H4 H10.
  destruct H; [| symmetry]; apply (anti_chain_not_comparable (limit_domain Omegas)); auto.
Qed.

Lemma local_step_rev_strong_functionality: forall m r h1 h2 k1 k2,
  prefix_history h1 h2 \/ prefix_history h2 h1 ->
  local_step_rev m r h1 k1 ->
  local_step_rev m r h2 k2 ->
  h1 = h2 /\ k1 = k2.
Proof.
  intros.
  destruct k1 as [n1 | n1 |], k2 as [n2 | n2 |].
  + pose proof local_step_rev_strong_functionality_aux_AA _ _ _ _ _ _ H H0 H1.
    destruct H2; subst; auto.
  + pose proof local_step_rev_strong_functionality_aux_AS _ _ _ _ _ _ H H0 H1.
    tauto.
  + pose proof local_step_rev_strong_functionality_aux_AF _ _ _ _ _ H H0 H1.
    tauto.
  + rewrite or_comm in H.
    pose proof local_step_rev_strong_functionality_aux_AS _ _ _ _ _ _ H H1 H0.
    tauto.
  + pose proof local_step_rev_strong_functionality_aux_SS _ _ _ _ _ _ H H0 H1.
    destruct H2; subst; auto.
  + pose proof local_step_rev_strong_functionality_aux_SF _ _ _ _ _ H H0 H1.
    tauto.
  + rewrite or_comm in H.
    pose proof local_step_rev_strong_functionality_aux_AF _ _ _ _ _ H H1 H0.
    tauto.
  + rewrite or_comm in H.
    pose proof local_step_rev_strong_functionality_aux_SF _ _ _ _ _ H H1 H0.
    tauto.
  + pose proof local_step_rev_strong_functionality_aux_FF _ _ _ _ H H0 H1.
    auto.
Qed.

Lemma local_step_rev_functionality: forall m r h k1 k2,
  local_step_rev m r h k1 ->
  local_step_rev m r h k2 ->
  k1 = k2.
Proof.
  intros.
  pose proof local_step_rev_strong_functionality _ _ _ _ _ _ (or_introl (prefix_history_refl _)) H H0.
  tauto.
Qed.

Lemma local_step_label_00_iff: forall h n, n = 0 /\ dir 0 h <-> local_step_label n h 0 0.
Proof.
  intros.
  split; intros.
  + destruct H; subst; apply label_0; auto.
  + inversion H; subst; auto.
Qed.

Lemma local_step_rev_00_ActiveBranch_iff: forall h n, local_step_rev 0 0 h (ActiveBranch n) <-> n = 0 /\ dir 0 h.
Proof.
  intros.
  split; intros.
  + inversion H; subst.
    rewrite local_step_label_00_iff; auto.
  + constructor.
    rewrite local_step_label_00_iff in H; auto.
Qed.

Lemma local_step_rev_00_SingleStreamEnd_iff: forall h n, local_step_rev 0 0 h (SingleStreamEnd n) <-> False.
Proof.
  intros.
  split; [| tauto].
  intros.
  inversion H; subst.
  pose proof labeled_in_dir _ _ _ _ H5.
  destruct (fun HH => ConvergeDir_mono dir 0 n HH h H0) as [h' [? ?]]; [omega |].
  specialize (H1 0 h' H2).
  apply H1.
  rewrite <- local_step_label_00_iff; auto.
Qed.

Lemma local_step_rev_00_FullStreamEnd_iff: forall h, local_step_rev 0 0 h FullStreamEnd <-> Omegas 0 h /\ ~ dir 0 h.
Proof.
  intros.
  split; intros.
  + inversion H; subst.
    assert (~ covered_by h (dir 0)).
    Focus 1. {
      intros [h' [? ?]].
      specialize (H0 0 h' H3).
      rewrite <- local_step_label_00_iff in H0.
      tauto.
    } Unfocus.
    split.
    - rewrite ConvergeDir_uncovered_limit_domain_spec by eauto. auto.
    - intro; apply H3; exists h; split; [apply prefix_history_refl | auto].
  + destruct H.
    assert (~ covered_by h (dir 0)).
    Focus 1. {
      rewrite <- covered_by_is_element; [auto | exact H | exact (MeasurableSubset_in_domain _ _)].
    } Unfocus.
    constructor.
    - intros; intro.
      apply H1; exists h'.
      rewrite <- local_step_label_00_iff in H3.
      tauto.
    - intros; intro.
      pose proof labeled_in_dir _ _ _ _ H3.
      destruct (fun HH => ConvergeDir_mono dir 0 n' HH h' H4) as [h'' [? ?]]; [omega |].
      apply H1; exists h''; split; auto.
      eapply prefix_history_trans; eauto.
    - rewrite <- ConvergeDir_uncovered_limit_domain_spec by eauto.
      auto.
Qed.

Lemma local_step_rev_mS_ActiveBranch_iff: forall m r h n, local_step_rev m (S r) h (ActiveBranch n) <-> exists n' h', n = S n' /\ prefix_history h' h /\ local_step_rev m r h' (ActiveBranch n') /\ dir n h /\ forall s, (l (S n')) h s -> ~ (filter m) s.
Proof.
  intros.
  split.
  + intros.
    inversion H; subst.
    inversion H4; subst.
    exists n0, h'; split; [| split; [| split]]; auto.
    constructor; auto.
  + intros [n' [h' [? [? [? [? ?]]]]]].
    subst n.
    inversion H1; subst.
    constructor.
    econstructor; eauto.
Qed.

Lemma local_step_rev_mS_SingleStreamEnd_iff: forall m r h n, local_step_rev m (S r) h (SingleStreamEnd n) <-> local_step_rev m r h (SingleStreamEnd n) \/ (exists n' h', n = S n' /\ prefix_history h' h /\ local_step_rev m r h' (ActiveBranch n') /\ dir n h /\ forall s, (l (S n')) h s -> (filter m) s).
Proof.
  intros.
  split.
  + intros.
    inversion H; subst.
    inversion H5; subst.
    destruct (lt_eq_lt_dec r0 r) as [[?H | ?H] | ?H].
    - left.
      constructor; auto.
      intros; intro.
      rename h'0 into h''.
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (prefix_history_comparable _ _ _ H4 H6) H3 H7) as [? | [? | ?]]; [| omega | omega].
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (or_introl H6) H7 H5) as [? | [? | ?]]; omega.
    - right.
      subst r0.
      exists n0, h'; split; [| split; [| split]]; auto.
      constructor; auto.
    - exfalso.
      pose proof local_step_label_backward _ _ _ (S r) _ H0 H3.
      destruct H6 as [n1 [h1 [? [? ?]]]].
      apply (H1 n1 h1); auto.
      eapply prefix_history_trans; eauto.
  + intros [?H | [n0 [h0 [? [? [? [? ?]]]]]]].
    - inversion H; subst.
      constructor; auto.
      intros; intro.
      pose proof local_step_label_backward _ _ _ r (S r) (le_n_Sn _) H2.
      destruct H3 as [n1 [h1 [? [? ?]]]].
      apply (H1 n1 h1); auto.
      eapply prefix_history_trans; eauto.
    - subst n.
      inversion H1; subst.
      constructor; [| econstructor; eauto].
      intros; intro.
      inversion H4; subst.
      rename h'0 into h''.
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (prefix_history_comparable _ _ _ H0 (prefix_history_trans _ _ _ H9 H)) H7 H8) as [? | [? | ?]]; [omega | | omega].
      destruct H5 as [? [? _]]; subst h'' n0.
      pose proof anti_chain_not_comparable _ _ _ H6 H2 H.
      subst h'.
      destruct (PrFamily.rf_complete _ _ (l (S n)) h) as [s ?]; [eapply MeasurableSubset_in_domain; eauto |].
      specialize (H3 _ H5).
      specialize (H13 _ H5).
      auto.
Qed.

Lemma local_step_rev_mS_FullStreamEnd_iff: forall m r h, local_step_rev m (S r) h FullStreamEnd <-> local_step_rev m r h FullStreamEnd \/ (exists n' h', prefix_history h' h /\ local_step_rev m r h' (ActiveBranch n') /\ ~ dir (S n') h).
Proof.
  intros.
  split.
  + intros.
    inversion H; subst.
(*
    destruct 
    inversion H5; subst.
    destruct (lt_eq_lt_dec r0 r) as [[?H | ?H] | ?H].
    - left.
      constructor; auto.
      intros; intro.
      rename h'0 into h''.
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (prefix_history_comparable _ _ _ H4 H6) H3 H7) as [? | [? | ?]]; [| omega | omega].
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (or_introl H6) H7 H5) as [? | [? | ?]]; omega.
    - right.
      subst r0.
      exists n0, h'; split; [| split; [| split]]; auto.
      constructor; auto.
    - exfalso.
      pose proof local_step_label_backward _ _ _ (S r) _ H0 H3.
      destruct H6 as [n1 [h1 [? [? ?]]]].
      apply (H1 n1 h1); auto.
      eapply prefix_history_trans; eauto.
  + intros [?H | [n0 [h0 [? [? [? [? ?]]]]]]].
    - inversion H; subst.
      constructor; auto.
      intros; intro.
      pose proof local_step_label_backward _ _ _ r (S r) (le_n_Sn _) H2.
      destruct H3 as [n1 [h1 [? [? ?]]]].
      apply (H1 n1 h1); auto.
      eapply prefix_history_trans; eauto.
    - subst n.
      inversion H1; subst.
      constructor; [| econstructor; eauto].
      intros; intro.
      inversion H4; subst.
      rename h'0 into h''.
      destruct (local_step_label_comparable_history_strict_order _ _ _ _ _ _ _ _ (prefix_history_comparable _ _ _ H0 (prefix_history_trans _ _ _ H9 H)) H7 H8) as [? | [? | ?]]; [omega | | omega].
      destruct H5 as [? [? _]]; subst h'' n0.
      pose proof anti_chain_not_comparable _ _ _ H6 H2 H.
      subst h'.
      destruct (PrFamily.rf_complete _ _ (l (S n)) h) as [s ?]; [eapply MeasurableSubset_in_domain; eauto |].
      specialize (H3 _ H5).
      specialize (H13 _ H5).
      auto.
Qed.
*)
Admitted.

Lemma raw_sstate_ActiveBranch_iff: forall m r n h' h s,
  prefix_history h h' ->
  local_step_rev m r h (ActiveBranch n) -> (l n h' s <-> raw_sstate m r h' s).
Proof.
  intros; split; intros.
  + pose proof PrFamily.rf_sound _ _ (l n) h' _ H1.
    inversion H0; subst.
    apply labeled_in_dir in H7.
    apply MeasurableSubset_in_domain in H7.
    pose proof anti_chain_not_comparable _ _ _ H7 H2 H.
    subst h'.
    eapply state_ActiveBranch; eauto.
  + inversion H1; subst;
    pose proof local_step_rev_strong_functionality m r h h' _ _ (or_introl H) H0 H2.
    - destruct H4.
      inversion H5; subst; auto.
    - inversion H4; congruence.
    - inversion H4; congruence.
Qed.

Lemma raw_sstate_SingleStreamEnd_iff: forall m r n h' h s,
  prefix_history h h' ->
  local_step_rev m r h (SingleStreamEnd n) -> (l n h' s <-> raw_sstate m r h' s).
Proof.
  intros; split; intros.
  + pose proof PrFamily.rf_sound _ _ (l n) h' _ H1.
    inversion H0; subst.
    apply labeled_in_dir in H8.
    apply MeasurableSubset_in_domain in H8.
    pose proof anti_chain_not_comparable _ _ _ H8 H2 H.
    subst h'.
    eapply state_SingleStreamEnd; eauto.
  + inversion H1; subst;
    pose proof local_step_rev_strong_functionality m r h h' _ _ (or_introl H) H0 H2.
    - inversion H4; congruence.
    - destruct H4.
      inversion H5; subst; auto.
    - inversion H4; congruence.
Qed.

Lemma raw_sstate_FullStreamEnd_iff: forall m r h' h s,
  prefix_history h h' ->
  local_step_rev m r h FullStreamEnd -> (limit l dir h' s <-> raw_sstate m r h' s).
Proof.
  intros; split; intros.
  + pose proof PrFamily.rf_sound _ _ (limit l dir) h' _ H1.
    inversion H0; subst.
    pose proof anti_chain_not_comparable _ _ _ H5 H2 H.
    subst h'.
    apply state_FullStreamEnd; eauto.
  + inversion H1; subst;
    pose proof local_step_rev_strong_functionality m r h h' _ _ (or_introl H) H0 H2.
    - inversion H4; congruence.
    - inversion H4; congruence.
    - destruct H4.
      inversion H5; subst; auto.
Qed.

Lemma local_step_rev_spec: forall m r h k,
  local_step_rev m r h k -> (exists n, Omegas n h) \/ limit_domain Omegas h.
Proof.
  intros.
  inversion H; subst.
  + left; exists n.
    apply labeled_in_dir in H0.
    eapply MeasurableSubset_in_domain; eauto.
  + left; exists n.
    apply labeled_in_dir in H1.
    eapply MeasurableSubset_in_domain; eauto.
  + right.
    auto.
Qed.

Lemma raw_sdomains_iff: forall m r h,
  raw_sdomains m r h <-> exists k, local_step_rev m r h k.
Proof.
  intros.
  split; intros.
  + inversion H; firstorder.
  + destruct H as [[ | |] ?].
    - eapply dom_ActiveBranch; eauto.
    - eapply dom_SingleStreamEnd; eauto.
    - eapply dom_FullStreamEnd; eauto.
Qed.


Lemma local_step_rev_SingleStreamEnd_Sn: forall m r h n, local_step_rev m r h (SingleStreamEnd n) -> local_step_rev m (S r) h (SingleStreamEnd n).
Proof.
  intros.
  inversion H; subst.
  constructor; auto.
  intros; intro.
  inversion H2; subst.
  rename h'0 into h''.
  apply (H1 n0 h''); auto.
  eapply prefix_history_trans; eauto.
Qed.

Lemma local_step_rev_FullStreamEnd_Sn: forall m r h, local_step_rev m r h FullStreamEnd -> local_step_rev m (S r) h FullStreamEnd.
Proof.
  intros.
  inversion H; subst.
  constructor; auto.
  intros; intro.
  inversion H4; subst.
  rename h'0 into h''.
  apply (H0 n h''); auto.
  eapply prefix_history_trans; eauto.
Qed.

Lemma raw_sdomains_legal: forall m r,
  LegalHistoryAntiChain (raw_sdomains m r).
Proof.
  intros ? ?.
  constructor.
  hnf; intros.
  rewrite raw_sdomains_iff in H0.
  rewrite raw_sdomains_iff in H1.
  destruct H0 as [k1 ?H], H1 as [k2 ?H].
  pose proof conflict_history_strict_conflict _ _ H.
  pose proof conflict_neq _ _ H.
  rewrite <- or_assoc in H2; destruct H2.
  + pose proof local_step_rev_strong_functionality _ _ _ _ _ _ H2 H1 H0.
    destruct H4; congruence.
  + apply local_step_rev_spec in H0.
    apply local_step_rev_spec in H1.
    apply (RandomVarDomainStream_and_limit_no_strict_conflict Omegas h1 h2); auto.
Qed.

Lemma raw_sdomains_same_covered: forall m r H H0,
  same_covered_anti_chain (Build_HistoryAntiChain _ (raw_sdomains m r) H) (Build_HistoryAntiChain _ (raw_sdomains m (S r)) H0).
Proof.
Admitted.

Lemma raw_sdomains_forward: forall m r H H0,
  future_anti_chain (Build_HistoryAntiChain _ (raw_sdomains m r) H) (Build_HistoryAntiChain _ (raw_sdomains m (S r)) H0).
Proof.
Admitted.

Lemma raw_sstate_partial_functionality: forall m r h s1 s2,
  raw_sstate m r h s1 -> raw_sstate m r h s2 -> s1 = s2.
Proof.
  intros.
  inversion H; inversion H0; subst;
  pose proof local_step_rev_functionality _ _ _ _ _ H1 H7;
  try congruence.
  + inversion H3; subst n0.
    apply (PrFamily.rf_partial_functionality _ _ (l n) h s1 s2 H2 H8).
  + inversion H3; subst n0.
    apply (PrFamily.rf_partial_functionality _ _ (l n) h s1 s2 H2 H8).
  + apply (PrFamily.rf_partial_functionality _ _ (limit l dir) h s1 s2 H2 H8).
Qed.

Lemma raw_sstate_sound: forall m r h s,
  raw_sstate m r h s -> raw_sdomains m r h.
Proof.
  intros.
  inversion H; subst.
  + eapply dom_ActiveBranch; eauto.
  + eapply dom_SingleStreamEnd; eauto.
  + eapply dom_FullStreamEnd; eauto.
Qed.

Lemma raw_sstate_complete: forall m r h,
  raw_sdomains m r h -> exists s, raw_sstate m r h s.
Proof.
  intros.
  inversion H; subst.
  + destruct (PrFamily.rf_complete _ _ (l n) h) as [s ?].
    - inversion H0; subst; auto.
      apply labeled_in_dir in H5.
      eapply MeasurableSubset_in_domain; eauto.
    - exists s.
      eapply state_ActiveBranch; eauto.
  + destruct (PrFamily.rf_complete _ _ (l n) h) as [s ?].
    - inversion H0; subst; auto.
      apply labeled_in_dir in H6.
      eapply MeasurableSubset_in_domain; eauto.
    - exists s.
      eapply state_SingleStreamEnd; eauto.
  + destruct (PrFamily.rf_complete _ _ (limit l dir) h) as [s ?].
    - inversion H0; subst; auto.
    - exists s.
      eapply state_FullStreamEnd; eauto.
Qed.

Lemma raw_sdir_in_raw_domains: forall m r,
  Included (raw_sdir m r) (raw_sdomains m r).
Proof.
  unfold Included, Ensembles.In.
  intros.
  inversion H; subst.
  eapply dom_ActiveBranch; eauto.
Qed.

Lemma raw_sdir_slow: forall m r h,
  (exists h', prefix_history h' h /\ (raw_sdir m r) h') \/ (forall s, raw_sstate m r h s <-> raw_sstate m (S r) h s).
Proof.
  intros.
  destruct (classic (exists k h', prefix_history h' h /\ local_step_rev m r h' k)) as [[[? | ? |] ?] | ?].
  + destruct H as [h' [? ?]]; left; exists h'.
    split; auto.
    econstructor; eauto.
  + destruct H as [h' [? ?]]; right.
    intros.
    pose proof local_step_rev_SingleStreamEnd_Sn _ _ _ _ H0.
    rewrite <- !raw_sstate_SingleStreamEnd_iff by eauto.
    reflexivity.
  + destruct H as [h' [? ?]]; right.
    intros.
    pose proof local_step_rev_FullStreamEnd_Sn _ _ _ H0.
    rewrite <- !raw_sstate_FullStreamEnd_iff by eauto.
    reflexivity.
  + right.
    intros.
Admitted.

Lemma raw_sstate_preserve: forall m r H (P: measurable_set (MetaState state)),
  PrFamily.is_measurable_set (fun h => raw_sdomains m r h /\ (forall s, raw_sstate m r h s -> P s)) (exist _ (raw_sdomains m r) H).
Admitted.

Lemma raw_sstate_inf_consist: forall m r h s,
  is_inf_history h ->
  raw_sstate m r h s ->
  s = NonTerminating _.
Proof.
  intros.
  destruct H0.
  + apply (inf_history_sound _ _ (l n) h); auto.
  + apply (inf_history_sound _ _ (l n) h); auto.
  + apply (inf_history_sound _ _ (limit l dir) h); auto.
Qed.

Lemma raw_sdir_measurable: forall m r H,
  PrFamily.is_measurable_set (raw_sdir m r) (exist _ (raw_sdomains m r) H).
Admitted.

Lemma raw_sdir_forward: forall m r H H0,
  future_anti_chain (Build_HistoryAntiChain _ (raw_sdir m r) H) (Build_HistoryAntiChain _ (raw_sdir m (S r)) H0).
Proof.
Admitted.

Lemma init_raw_dom_is_limit_dom: forall (Omegas0: RandomVarDomainStream) m,
  (forall r h, Omegas0 r h = raw_sdomains m r h) ->
  (forall h, limit_domain Omegas0 h <-> raw_sdomains (S m) 0 h).
Proof.
  intros.
  assert (limit_domain Omegas0 h <->
   (forall r n,
    exists (r' : nat) (h' : RandomHistory),
      r' > r /\
      prefix_history (fstn_history n h) h' /\
      prefix_history h' h /\ raw_sdomains m r' h')).
  Focus 1. {
    rewrite limit_domain_spec.
    apply Coqlib.forall_iff; intros r.
    apply Coqlib.forall_iff; intros n.
    apply Coqlib.ex_iff; intros r'.
    apply Coqlib.ex_iff; intros h'.
    rewrite H; reflexivity.
  } Unfocus.
  rewrite H0; clear Omegas0 H H0.
  split; intros.
  + destruct (classic (exists r h' k, prefix_history h' h /\ raw_sdomains m r h' /\ local_step_rev m r h' k /\ match k with | ActiveBranch _ => False | _ => True end)).
Admitted.

Lemma init_raw_state_is_limit_state: forall (Omegas0: RandomVarDomainStream) (l0: ProgStateStream Omegas0 state) (dir0: ConvergeDir l0) m,
  (forall r h, Omegas0 r h = raw_sdomains m r h) ->
  (forall r h, dir0 r h = raw_sdir m r h) ->
  (forall r h s, l0 r h s = raw_sstate m r h s) ->
  (forall h s, limit l0 dir0 h s <-> raw_sstate (S m) 0 h s).
Admitted.

Section ind.

Variable (m: nat).
Hypothesis (H: is_measurable_subspace (raw_sdomains m 0)).

Definition sub_domain'' (r: nat): RandomVarDomain.
  refine (exist _ (raw_sdomains m r) _).
  induction r.
  + auto.
  + pose proof raw_sdomains_legal m r.
    pose proof raw_sdomains_legal m (S r).
    change (raw_sdomains m (S r)) with
        (Build_HistoryAntiChain _ (raw_sdomains m (S r)) H1: Ensemble _).
    apply is_measurable_subspace_same_covered with (Build_HistoryAntiChain _ (raw_sdomains m r) H0); auto.
    apply raw_sdomains_same_covered.
Defined.

Definition sub_domain': RandomVarDomainStream.
  refine (Build_RandomVarDomainStream sub_domain'' _ _).
  + intros; apply raw_sdomains_same_covered.
  + intros; apply raw_sdomains_forward.
Defined.

Definition sub_state': ProgStateStream sub_domain' state :=
  fun r =>
    Build_ProgState _ _ _
     (PrFamily.Build_MeasurableFunction (sub_domain'' r) _ _
       (raw_sstate m r)
       (raw_sstate_partial_functionality _ _)
       (raw_sstate_complete _ _)
       (raw_sstate_sound _ _)
       (raw_sstate_preserve _ _ _))
     (raw_sstate_inf_consist _ _).

Definition sub_dir'' (r: nat): MeasurableSubset (sub_domain'' r) :=
  exist _ (raw_sdir m r) (raw_sdir_measurable m r _).

Definition sub_dir': ConvergeDir sub_state'.
  refine (Build_ConvergeDir sub_domain' _ _ _ sub_dir'' _ _).
  + intros. apply raw_sdir_forward.
  + intros. apply raw_sdir_slow.
Defined.

Lemma init_dom_is_limit_dom': forall h, limit_domain sub_domain' h <-> raw_sdomains (S m) 0 h.
Proof.
  apply init_raw_dom_is_limit_dom.
  intros; reflexivity.
Qed.

Lemma measurable_ind: is_measurable_subspace (raw_sdomains (S m) 0).
  apply is_measurable_subspace_proper with (limit_domain sub_domain').
  + symmetry; rewrite Same_set_spec; exact init_dom_is_limit_dom'.
  + apply (proj2_sig (limit_domain sub_domain')).
Qed.

End ind.

Lemma local_step_rev_00_iff: forall h, (exists k, local_step_rev 0 0 h k) <-> Omegas 0 h.
Proof.
  intros.
  split; [intros [? ?] | intros].
  + inversion H; subst.
    - rewrite local_step_rev_00_ActiveBranch_iff in H.
      destruct H.
      eapply MeasurableSubset_in_domain; eauto.
    - rewrite local_step_rev_00_SingleStreamEnd_iff in H.
      tauto.
    - rewrite local_step_rev_00_FullStreamEnd_iff in H.
      tauto.
  + destruct (classic (dir 0 h)).
    - exists (ActiveBranch 0).
      rewrite local_step_rev_00_ActiveBranch_iff; auto.
    - exists FullStreamEnd.
      rewrite local_step_rev_00_FullStreamEnd_iff; auto.
Qed.

Lemma raw_sdomains_00_iff: forall h, raw_sdomains 0 0 h <-> Omegas 0 h.
Proof.
  intros.
  rewrite <- local_step_rev_00_iff.
  split; intros.
  + inversion H; subst; firstorder.
  + destruct H as [[? | ? |] ?].
    - eapply dom_ActiveBranch; eauto.
    - eapply dom_SingleStreamEnd; eauto.
    - apply dom_FullStreamEnd; auto.
Qed.

Lemma measure0: forall m, is_measurable_subspace (raw_sdomains m 0).
Proof.
  intros.
  induction m.
  + apply is_measurable_subspace_proper with (Omegas 0).
    - rewrite Same_set_spec; exact raw_sdomains_00_iff.
    - apply (proj2_sig (Omegas 0)).
  + apply measurable_ind; auto.
Qed.

Definition sub_domain (m: nat): RandomVarDomainStream := sub_domain' m (measure0 m).

Definition sub_state (m: nat): ProgStateStream (sub_domain m) state := sub_state' m (measure0 m).

Definition sub_dir (m: nat): ConvergeDir (sub_state m) := sub_dir' m (measure0 m).

End CutStream.