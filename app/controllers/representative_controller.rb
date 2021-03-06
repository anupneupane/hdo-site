# encoding: UTF-8

class RepresentativeController < ApplicationController
  layout 'logged_in'
  before_filter :authenticate_representative!
  before_filter :require_edit, only: :create_answer

  def index
    questions = current_representative.questions.approved.order('created_at DESC') # TODO: use approved_at (also in the view)?
    answers   = current_representative.answers.order('created_at DESC')

    @unanswered_questions = questions.unanswered
    @published_answers    = questions.answered.where('answers.status' => 'approved')
    @pending_answers      = answers.pending
    @rejected_answers     = answers.rejected

    # TODO:
    #
    # - plural if size == 1
    # - i18n
    # - specs

    @counts = [
      ['spørsmål venter på svar', @unanswered_questions.size, false],
      ['svar til godkjenning', @pending_answers.size, true],
      ['svar publisert', @published_answers.size, true]
    ]

    @questions = questions.sort_by { |q| question_sorter q }
  end

  def show_question
    @question = Question.approved.find(params[:id])
    @answer   = Answer.new(question: @question, representative: @question.representative)
  end

  def create_answer
    question = Question.find(params[:id])
    ensure_representative_authorized(question)

    @answer = question.build_answer(params[:answer])
    if question.save
      redirect_to representative_root_path, notice: t('app.answers.edit.created')
    else
      if @answer.question
        redirect_to representative_question_path(@answer.question_id, answer: @answer), alert: @answer.errors.full_messages.to_sentence
      else
        redirect_to representative_root_path, alert: @answer.errors.full_messages.to_sentence
      end
    end
  end

  private

  def question_sorter(question)
    if question.answer.nil?
      0
    elsif question.answer.rejected?
      1
    elsif question.answer.pending?
      2
    else
      3
    end
  end

  def ensure_representative_authorized(question)
    unless Pundit.policy(current_representative, question).answer?
      raise Pundit::NotAuthorizedError
    end
  end

end