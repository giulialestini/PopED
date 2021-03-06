#' Evaluate power of a design for detecting a parameter to be non-zero using the
#' linear Wald test.
#'
#' This tunction evaluates the design defined in a poped database.
#'
#' @param poped.db A poped database
#' @param bpopIdx Indices for unfixed parameters for which power should be
#'   evaluated for being non-zero
#' @param alpha Type 1 error (default = 0.05)
#' @param power Targeted power (default = 80\%)
#' @param twoSided Is two-sided test (default = TRUE)
#' @param fim Optional to provide FIM from a previous calculation
#' @param out Optional to provide output from a previous calculation (e.g.,
#'   calc_ofv_and_fim, ...)
#' @param ... Extra parameters passed to \code{\link{calc_ofv_and_fim}} and
#'   \code{\link{get_rse}}
#' @param find_min_n Should the function compute the minimum n needed (given the
#'   current design) to achieve the desired power?
#' @return A list of elements evaluating the current design including the power.
#' @references \enumerate{ \item Retout, S., Comets, E., Samson, A., and Mentre,
#'   F. (2007). Design in nonlinear mixed effects models: Optimization using the
#'   Fedorov-Wynn algorithm and power of the Wald test for binary covariates.
#'   Statistics in Medicine, 26(28), 5162-5179.
#'   \url{https://doi.org/10.1002/sim.2910}. \item Ueckert, S., Hennig, S.,
#'   Nyberg, J., Karlsson, M. O., and Hooker, A. C. (2013). Optimizing disease
#'   progression study designs for drug effect discrimination. Journal of
#'   Pharmacokinetics and Pharmacodynamics, 40(5), 587-596.
#'   \url{https://doi.org/10.1007/s10928-013-9331-3}. }
#'
#' @example tests/testthat/examples_fcn_doc/examples_evaluate_power.R
#'
#' @family evaluate_design
#' @export

evaluate_power <- function(poped.db, bpopIdx=NULL, fim=NULL, out=NULL, alpha=0.05, power=80, twoSided=TRUE, find_min_n=TRUE,...) {
  # If two-sided then halve the alpha
  if (twoSided == TRUE) alpha = alpha/2
  
  # Check if bpopIdx is given and within the non-fixed parameters
  if (is.null(bpopIdx)) stop("Population parameter index must be given in bpopIdx")
  if (!all(bpopIdx %in% which(poped.db$parameters$notfixed_bpop==1))) stop("bpopIdx can only include non-fixed population parameters bpop")
  if (poped.db$parameters$param.pt.val$bpop[bpopIdx]==0) 
    stop("
  Population parameter is assumed to be zero, 
  there is 0% power in identifying this parameter 
  as non-zero assuming no bias in parameter estimation")
  
  # Prepare output structure with at least out$fim available
  if (is.null(fim) & is.null(out$fim)) {
    out <- calc_ofv_and_fim(poped.db,...)
  } else if (!is.null(fim)) {
    out = list(fim = fim)
  }
  # Add out$rse
  out$rse <- get_rse(out$fim,poped.db,...)

  # Derive power and RSE needed for the selected parameter(s)
  norm.val = abs(qnorm(alpha, mean=0, sd=1))
  val = poped.db$parameters$param.pt.val$bpop[bpopIdx]
  rse = out$rse[which(poped.db$parameters$notfixed_bpop==1)[bpopIdx]] # in percent!!

  # Following the paper of Retout et al., 2007 for the Wald-test:
  powPred = round(100*(1 - stats::pnorm(norm.val-(100/rse)) + stats::pnorm(-norm.val-(100/rse))), digits=1)
  needRSE = 100/(norm.val-stats::qnorm(1-power/100))

  out$power = data.frame(Value=val, RSE=rse, predPower=powPred, wantPower=power, needRSE=needRSE)
  
  # find the smallest n to achieve the wanted power.
  if(find_min_n){
    res <- optimize_n(poped.db,bpopIdx=bpopIdx,needRSE=needRSE)
    out$power$min_N=res$par
  }
  
  return(out)
}